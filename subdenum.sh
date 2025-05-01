#!/bin/bash

# Demo Command
# subdenum yahoo.com wordlist.txt resolver.txt output_dir

# Input Variables
# TARGET=$1
# WORDLIST=$2
# RESOLVER=$3
# OUTPUT_DIR=$4

# Input Variables
TARGET=$1
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
RESOLVER="resolver.txt"
OUTPUT_DIR="$HOME/data/$TARGET/recon/subdomain"
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Funtions
# silent_out() {
#     "$@" > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
# }

# Tools to run

# subfinder
TOOL="subfinder"
echo -e "\n[+] Running subfinder ..."
subfinder -d $TARGET > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
echo -e "[-] Completed subfinder.\n"

# sublist3r
TOOL="sublist3r"
echo -e "\n[+] Running $TOOL ..."
sublist3r -d $TARGET > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
echo -e "[-] Completed $TOOL.\n"

# assetfinder
TOOL="assetfinder"
echo -e "\n[+] Running $TOOL ..."
assetfinder -subs-only $TARGET > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
echo -e "[-] Completed $TOOL.\n"

# amass


# findomain
TOOL="findomail"
echo -e "\n[+] Running $TOOL ..."
findomain -q -t $TARGET > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
echo -e "[-] Completed $TOOL.\n"

# ffuf
TOOL="findomain"
echo -e "\n[+] Running $TOOL ..."
findomain -q -t $TARGET > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
echo -e "[-] Completed $TOOL.\n"

# pureDNS
TOOL="puredns"
echo -e "\n[+] Running $TOOL ..."
puredns bruteforce /usr/share/ bing.com -q -r resolver.txt > $OUTPUT_DIR/$TOOL.txt # > /dev/null 2>&1
echo -e "[-] Completed $TOOL.\n"

# crt.sh


echo -e "\n[-]Scan Complete.\n\nSubdomains are saved in - $OUTPUT_DIR/"