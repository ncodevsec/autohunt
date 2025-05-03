#!/bin/bash

# Check for required tools
TOOLS=(assetfinder jq curl subfinder sublist3r findomain puredns massdns ffuf seclists)

# go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

for tool in "${TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "[-] Error: $tool is not installed. Please install it before running the script."
        exit 1
    fi
done

# Target Domain
TARGET=$1

# Scan Mode
SCAN_MODE=$2

# Wordlist
# WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"
WORDLIST="/usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top500.txt"

# Resolver
RESOLVER="resolver.txt"

# Output Directory
OUTPUT_DIR="$HOME/data/$TARGET/subdomain"

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Funtions
run() {
    local TOOL=$1
    local COMMAND=$2
    local RESULT=$3
    echo "--------------------------------------------------"
    sleep 0.2
    echo -e ":: $TOOL\t\t- Running"
    if [ "$RESULT" = "save" ]; then
        local PROMPT="$COMMAND > $OUTPUT_DIR/$TOOL.txt"
        # echo -e ":: Prompt\t\t- $PROMPT"
        eval "$PROMPT"
    elif [ "$RESULT" = "no-save" ]; then
        local PROMPT="$COMMAND > /dev/null" # 2>&1
        # echo -e ":: Prompt\t\t- $PROMPT"
        eval "$PROMPT"
    fi
    echo -e "\t\t\t- Scan Complete"
    sleep 0.3
}

# Tools to run

echo "--------------------------------------------------"
echo -e ":: Tool\t\t\t: subdenum"
echo -e ":: Target\t\t: $TARGET"

# amass
if [ "$SCAN_MODE" != "fast" ]; then
    echo -e ":: Scan Mode\t\t: Fast"
else
    echo -e ":: Scan Mode\t\t: Deep"
    run "amass" "amass enum -d $TARGET -silent -nocolor | grep -E '\.${TARGET}$'" save
fi

# assetfinder
run "assetfinder" "assetfinder -subs-only $TARGET" save

# crt.sh
run "crt" "curl -s 'https://crt.sh/?q=%25.$TARGET&output=json' | jq -r '.[].name_value'" save

# ffuf
run "ffuf" "ffuf -w $WORDLIST -u https://FUZZ.$TARGET -mc 200 -s | sed 's/^/&.$TARGET/'" save

# findomain
run "findomain" "findomain -q -t $TARGET" save

# pureDNS
run "puredns" "puredns bruteforce $WORDLIST $TARGET -q -r $RESOLVER" save 

# subfinder
run "subfinder" "subfinder -d $TARGET -silent" save

# sublist3r
run "sublist3r" "sublist3r -d $TARGET -n 2> /dev/null | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u" save

echo ":: Scanning Complete"
echo ":: Subdomains are saved in - $OUTPUT_DIR/"

# marge all unique
echo -e "\n:: Filtering out unique subdomains and marging them all together"
run "sort" "cat $OUTPUT_DIR/* | sort -u" save 
echo -e "\t\t\t- Marging Complete."

# httpx - Filter out Live Subdomains
run "httpx" "cat $OUTPUT_DIR/sort.txt | httpx -silent -nc -status-code -t 500 | grep '\[20' | awk '{print \$1}'" save

# aquatone - Site Mapping & Capturing Screenshot
run "aquatone" "mkdir $OUTPUT_DIR/aquatone && cat $OUTPUT_DIR/httpx.txt | aquatone -out $OUTPUT_DIR/aquatone"
echo -e ":: Screenshots are saved in $OUTPUT_DIR/aquatone/screenshots/"
echo -e ":: To view all Screenshots in a single file, visit - $OUTPUT_DIR/aquatone/aquatone_report.html"

echo ":: Everything Complete. Now you are able to see the result. "