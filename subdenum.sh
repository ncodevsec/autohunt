#!/bin/bash

# Check for required tools
TOOLS=(assetfinder jq curl subfinder sublist3r findomain puredns massdns ffuf seclists)

for tool in "${TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "[-] Error: $tool is not installed. Please install it before running the script."
        exit 1
    fi
done

# Demo Command
# subdenum yahoo.com wordlist.txt resolver.txt output_dir a

# Input Variables
TARGET=$1
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"
RESOLVER="resolver.txt"
OUTPUT_DIR="$HOME/data/$TARGET/recon/subdomain"
WRITE_MODE=$2


# Directory Configure
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
        local PROMPT="$TOOL $COMMAND > $OUTPUT_DIR/$TOOL.txt"
        echo -e ":: Prompt\t- $PROMPT"
        eval "$PROMPT"
    elif [ "$RESULT" = "no-save" ]; then
        local PROMPT="$TOOL $COMMAND > /dev/null" # 2>&1
        echo -e ":: Prompt\t- $PROMPT"
        eval "$PROMPT"
    fi
    echo -e "\t\t\t- Scan Complete"
}

# Tools to run

echo -e "\nScanning subdomains on $TARGET"

# amass
# run amass "-h" no-save

# assetfinder
run assetfinder "-subs-only $TARGET" save

# crt.sh
run curl "-s 'https://crt.sh/?q=%25.$TARGET&output=json' | jq -r '.[].name_value'" save

# ffuf
run ffuf "-w $WORDLIST -u https://FUZZ.$TARGET -mc 200 -s" save

# findomain
run findomain "-q -t $TARGET" save

# pureDNS
run puredns "bruteforce $WORDLIST $TARGET -q -r $RESOLVER" save 

# subfinder
run subfinder "-d $TARGET -silent" save

# sublist3r
run sublist3r "-d $TARGET -n 2> /dev/null | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u" save

echo ":: Scanning Complete"
echo ":: Subdomains are saved in - $OUTPUT_DIR/"

# marge all unique
echo -e "\n:: Filtering out unique subdomains and marging them all together"
cat * | sort -u > $OUTPUT_DIR/all.txt
echo "   Marging Complete."