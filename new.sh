#!/bin/bash

# Check for required tools
TOOLS=(assetfinder jq curl subfinder sublist3r findomain puredns massdns ffuf seclists)

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
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"

# Resolver
RESOLVER="resolver.txt"

if [ ! -f "$RESOLVER" ]; then
    echo "[-] Error: Resolver file '$RESOLVER' not found. Please provide a valid resolver file."
    exit 1
fi

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
}

if [ "$SCAN_MODE" = "fast" ]; then
    echo -e "Scan Mode\t\t: Fast"
else
    echo -e "Scan Mode\t\t: Deep"
    run "amass" "amass enum -d $TARGET -silent -nocolor | grep -E '\.${TARGET}$'" save
fi
    echo -e "Scan Mode\t\t: Fast"
else
    echo -e "Scan Mode\t\t: Deep"
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

cat $OUTPUT_DIR/*.txt | sort -u > $OUTPUT_DIR/all.txt
echo ":: Subdomains are saved in - $OUTPUT_DIR/"

# marge all unique
echo -e "\n:: Filtering out unique subdomains and marging them all together"
cat * | sort -u > $OUTPUT_DIR/all.txt
echo "   Marging Complete."

# httpx - Filter out Live Subdomains
run "httpx" "cat $OUTPUT_DIR/all.txt | httpx -silent -nc -status-code | grep '\[200\]' | awk '{print $1}'" save

# aquatone - Capturing Screenshot
run "aquatone" "cat $OUTPUT_DIR/httpx.txt | aquatone"
echo -e ":: Screenshots are saved in $PWD/aquatone/screenshots/"
echo -e ":: To view all Screenshots in a single file, visit - $PWD/aquatone/aquatone_report.html"

echo ":: Everything Complete. Now you are able to see the result. "