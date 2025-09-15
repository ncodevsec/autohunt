#!/bin/bash

# Check for required tools
TOOLS=(assetfinder jq curl subfinder sublist3r findomain puredns massdns ffuf)

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

if [ ! -f "$WORDLIST" ]; then
    echo "[-] Error: Seclist is not installed. Please install it before running the script."
    exit 1
fi

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolver
RESOLVER="./resolver.txt"

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
        local PROMPT="$COMMAND > /dev/null"
        # echo -e ":: Prompt\t\t- $PROMPT"
        eval "$PROMPT"
    else 
        local PROMPT="$COMMAND"
        # echo -e ":: Prompt\t\t- $PROMPT"
        eval "$PROMPT"
    fi
    echo -e "\t\t\t- Finish"
    sleep 0.3
}

# Tools to run

echo "--------------------------------------------------"
echo -e ":: Tool\t\t\t: subdenum"
echo -e ":: Target\t\t: $TARGET"

if [ "$SCAN_MODE" == "deep" ]; then
    echo -e ":: Scan Mode\t\t: Deep"

    # amass
    run "amass" "amass enum -d "$TARGET" -silent -nocolor -o $OUTPUT_DIR/amass_raw.txt && cat $OUTPUT_DIR/amass_raw.txt | grep -E "\.$TARGET" | awk '{print \$1}'" save

    # ffuf
    run "ffuf" "ffuf -w "$WORDLIST" -u https://FUZZ.$TARGET -of json -o $OUTPUT_DIR/ffuf.json &> /dev/null && jq -r '.results[].url' "$OUTPUT_DIR/ffuf.json" | sed 's|https\?://||' > "$OUTPUT_DIR/ffuf.txt""
else
    echo -e ":: Scan Mode\t\t: Fast"
fi

echo -e "\n:: Running subdomain finding tools"
# assetfinder
run "assetfinder" "assetfinder -subs-only $TARGET" save

# crt.sh
run "crt" "curl -s 'https://crt.sh/?q=%25.$TARGET&output=json' | jq -r '.[].name_value'" save

# findomain
run "findomain" "findomain -q -t $TARGET" save

# pureDNS
run "puredns" "puredns bruteforce $WORDLIST $TARGET -q -r  $SCRIPT_DIR/resolver.txt" save 

# subfinder
run "subfinder" "subfinder -d $TARGET -silent" save

# sublist3r
run "sublist3r" "sublist3r -d $TARGET -n 2> /dev/null | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u" save


# marge unique subdomains
echo -e "\n:: Marging Unique Subdomains"
run "sort" "cat $OUTPUT_DIR/* | sort -u" save 

# httpx - Filter out Live Subdomains
echo -e "\n:: Filtering Live Subdomains"
run "httpx" "cat $OUTPUT_DIR/sort.txt | httpx -silent -nc -status-code -t 500 | grep '\[20' | awk '{print \$1}'" save

# aquatone - Site Mapping & Capturing Screenshot
aquatone() {
    if [ ! -d "$OUTPUT_DIR/aquatone" ]; then
        mkdir -p "$OUTPUT_DIR/aquatone"
    fi
    run "aquatone" "cat $OUTPUT_DIR/httpx.txt | aquatone -out $OUTPUT_DIR/aquatone/ -scan-timeout 5000 -screenshot-timeout 180000"
    # run "aquatone" "cat $OUTPUT_DIR/httpx.txt | aquatone -out $OUTPUT_DIR/aquatone/"
    echo -e ":: Aquatone Dir\t: $OUTPUT_DIR/aquatone"

    # echo -e ":: Screenshots are saved in $OUTPUT_DIR/aquatone/screenshots/"
    # echo -e ":: To view all Screenshots in a single file, visit - $OUTPUT_DIR/aquatone/aquatone_report.html"
}
# aquatone

# Modify final files
if [ -d "$OUTPUT_DIR/sort.txt" ]; then
    mv $OUTPUT_DIR/sort.txt $OUTPUT_DIR/all_subdomains.txt
fi
if [ -d "$OUTPUT_DIR/httpx.txt" ]; then
    mv $OUTPUT_DIR/httpx.txt $OUTPUT_DIR/live_subdomains.txt
fi

# Removing extra files
if [ -d "$OUTPUT_DIR/amass_raw.txt" ]; then
    rm $OUTPUT_DIR/amass_raw.txt
fi
if [ -d "$OUTPUT_DIR/ffuf.json " ]; then
    rm $OUTPUT_DIR/ffuf.json
fi

echo ":: Scan Complete."
echo ":: Subdomains are saved in - $OUTPUT_DIR"

# echo "\n:: Live Subdomain List"
# echo "--------------------------------------------------"
# cat $OUTPUT_DIR/live_subdomains.txt




