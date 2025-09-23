#!/bin/bash

# source "$(dirname "${BASH_SOURCE[0]}")/installation-checker.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
INFO='\033[0;36m'
NC='\033[0m' # No Color

# Common String Variables
DEVIDER="--------------------------------------------------"

# List of required tools
tools=(
    assetfinder
    jq
    curl
    findomain
    puredns
    subfinder
    sublist3r
    amass
    ffuf
    sort
    sed
    httpx
    csvcut
    aquatone
)

# Check required tools are installed or not
echo -e "${YELLOW}[+] Checking requirements...${NC}"

# Loop through the list of tools
for tool in "${tools[@]}"; do
    # Check if the tool is in the system's PATH
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}[-] $tool is not installed. Attempting to install...${NC}"
        # NOTE: This assumes a Debian-based system (like Ubuntu) using 'apt'.
        # You may need to change 'apt-get' to your system's package manager (e.g., 'yum', 'pacman', 'brew').
        # Some tools may require installation from source or other methods.
        sudo apt-get install -y "$tool" &> /dev/null
        
        # Verify installation
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}[!] Error : Failed to install $tool. Please install it manually.${NC}"
            exit 1
        else
            echo -e "${GREEN}[+] Successfully installed $tool.${NC}"
        fi
    fi
done

echo -e "${GREEN}[+] All required tools are installed.${NC}"

# Target Domain
TARGET=$1

# Scan Mode
SCAN_MODE=$2

# Wordlist
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"
# WORDLIST="/usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top500.txt"

if [ ! -f "$WORDLIST" ]; then
    echo -e "${RED}[-] Error:${NC} Seclist is not installed. Please install it before running the script."
    exit 1
fi

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolver
RESOLVER="./resolver.txt"

# Output Directory
OUTPUT_DIR="$HOME/bug_hunting_data/$TARGET/subdomain"

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Funtions
run() {
    local TOOL=$1
    local COMMAND=$2
    local RESULT=$3
    local SHOW_COUNT=$4
    # echo $DEVIDER
    # echo -e "\n"
    sleep 0.2
    echo -e "${BLUE}[-]${NC} Running\t: ${BLUE}$TOOL${NC}"
    # echo -e "${YELLOW}[-]${NC} Status\t: ${YELLOW}Running${NC}"
    local PROMPT="$COMMAND"
    if [ "$RESULT" = "save" ]; then
        PROMPT+=" > $OUTPUT_DIR/$TOOL.txt"
    elif [ "$RESULT" = "no-save" ]; then
        PROMPT+=" &> /dev/null"
    fi

    if ! eval "$PROMPT"; then
        echo -e "${RED}[!]${NC} Status\t:${NC} ${RED}Error on $TOOL${NC}."
    else
        if [ "$SHOW_COUNT" = "show" ] && [ -f "$OUTPUT_DIR/$TOOL.txt" ]; then
            local output_file="$OUTPUT_DIR/$TOOL.txt"
            if [ -s "$output_file" ]; then
                local line_count
                line_count=$(wc -l < "$output_file")
                echo -e "${YELLOW}[i]${NC} Found\t: ${YELLOW}${line_count// /} items${NC}"
            fi
        fi
        echo -e "${GREEN}[+]${NC} Status\t: ${GREEN}Finished${NC}"
    fi
    sleep 0.3
}

# Tools to run
echo -e "\n${YELLOW}[+] Script Overview${NC}"
echo -e "$DEVIDER"
echo -e "${BLUE}[-]${NC} Task\t: ${GREEN}Subdomain Enumeration${NC}"
echo -e "${BLUE}[-]${NC} Target\t: ${GREEN}$TARGET${NC}"

if [ "$SCAN_MODE" == "deep" ]; then
    echo -e "${INFO}[+]${NC} Scan\t: ${INFO}Deep${NC}"
else
    echo -e "${BLUE}[-]${NC} Scan\t: ${GREEN}Fast${NC}"
fi

echo -e "\n${YELLOW}[+] Enumerating Subdomains${NC}"
echo $DEVIDER
# assetfinder
run "assetfinder" "assetfinder -subs-only $TARGET" save show

# # crt.sh
run "crt" "curl -s 'https://crt.sh/?q=%25.$TARGET&output=json' | jq -r '.[].name_value'" save show

# findomain
run "findomain" "findomain -q -t $TARGET" save show

# pureDNS
run "puredns" "puredns bruteforce $WORDLIST $TARGET -q -r  $SCRIPT_DIR/resolver.txt" save show

# subfinder
run "subfinder" "subfinder -d $TARGET -silent" save show

# sublist3r
run "sublist3r" "sublist3r -d $TARGET -n 2> /dev/null | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u" save show

# Deep Scan
if [ "$SCAN_MODE" == "deep" ]; then
    # amass
    run "amass" "amass enum -d "$TARGET" -silent -nocolor -o $OUTPUT_DIR/amass_raw.txt && cat $OUTPUT_DIR/amass_raw.txt | grep -E \"\\.$TARGET\" | awk '{print \$1}'" save show

    # Removing extra files
    if [ -f "$OUTPUT_DIR/amass_raw.txt" ]; then
        rm "$OUTPUT_DIR/amass_raw.txt"
    fi

    # ffuf
    run "ffuf" "ffuf -w "$WORDLIST" -u https://FUZZ.$TARGET -of json -o $OUTPUT_DIR/ffuf.json &> /dev/null && jq -r '.results[].url' "$OUTPUT_DIR/ffuf.json" | sed 's|https\?://||' > "$OUTPUT_DIR/ffuf.txt"" "" "yes"

    # Removing extra files
    if [ -f "$OUTPUT_DIR/ffuf.json" ]; then
        rm "$OUTPUT_DIR/ffuf.json"
    fi
fi

# marge unique subdomains
echo -e "\n${YELLOW}[+] Merging Unique Subdomains${NC}"
echo $DEVIDER
# sort - Removing duplicates and sorting assending
run "sort" "cat $OUTPUT_DIR/* | sort -u" save
# sed - Removing duplicates with https://, http://
run "sed" "sed -E 's#https?://##g' $OUTPUT_DIR/sort.txt" save
if [ -f "$OUTPUT_DIR/sed.txt" ]; then
    mv $OUTPUT_DIR/sed.txt $OUTPUT_DIR/all.txt
fi

# httpx - Filter out Live Subdomains
echo -e "\n${YELLOW}[+] Checking Subdomains Status${NC}"
echo $DEVIDER
run "httpx" "cat $OUTPUT_DIR/all.txt | httpx -o $OUTPUT_DIR/httpx.csv -csv" no-save

# csvcut - Cleanning & Formating the CSV file
if [ -f "$OUTPUT_DIR/httpx.csv" ]; then
    run "csvcut" "csvcut -c url,status_code,location,title,path,content_type,webserver,tech,cname,host,a,aaaa,resolvers $OUTPUT_DIR/httpx.csv > $OUTPUT_DIR/subdomains.csv"
fi

# aquatone - Site Mapping & Capturing Screenshot
aquatone() {
    if [ ! -d "$OUTPUT_DIR/aquatone" ]; then
        mkdir -p "$OUTPUT_DIR/aquatone"f
    fi
    run "aquatone" "cat $OUTPUT_DIR/httpx.txt | aquatone -out $OUTPUT_DIR/aquatone/ -scan-timeout 5000 -screenshot-timeout 180000"
    # run "aquatone" "cat $OUTPUT_DIR/httpx.txt | aquatone -out $OUTPUT_DIR/aquatone/"
    echo -e "[+] Aquatone Dir\t: ${YELLOW}$OUTPUT_DIR/aquatone${NC}"

    # echo -e "[+] Screenshots are saved in $OUTPUT_DIR/aquatone/screenshots/"
    # echo -e "[+] To view all Screenshots in a single file, visit - $OUTPUT_DIR/aquatone/aquatone_report.html"
}
# aquatone

echo -e "\n${GREEN}[+] Subdomain Enumeration Complete${NC}"
echo $DEVIDER
# echo -e "\n${GREEN}[+]${NC} Scan Status\t: Complete${NC}"
TOTAL_SUBS=$(wc -l < "$OUTPUT_DIR/all.txt")
echo -e "${YELLOW}[+]${NC} Output Path\t: ${YELLOW}$OUTPUT_DIR${NC}"
echo -e "${INFO}[+]${NC} Total Found\t: ${INFO}$TOTAL_SUBS items${NC}"