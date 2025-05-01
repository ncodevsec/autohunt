#!/bin/bash

# Get Target


# Funtions
silent() {
    "$@" > /dev/null 2>&1
}



# Set Target
TARGET=$1

# Directory
DIR="~/data/$TARGET/recon/subdomain"
if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
fi

# Tools to run

# subfinder
TOOL="subfinder"
echo -e "\n[+] Running subfinder ..."
subfinder -d $TARGET -silent -o $DIR/$TOOL.txt
echo -e "[-] Completed subfinder.\n"

# sublist3r
TOOL="sublist3r"
echo -e "\n[+] Running $TOOL ..."
silent sublist3r -d $TARGET -o $DIR/$TOOL.txt
echo -e "[-] Completed $TOOL.\n"

# assetfinder
TOOL="assetfinder"
echo -e "\n[+] Running $TOOL ..."
silent assetfinder -subs-only $TARGET > $DIR/$TOOL.txt
echo -e "[-] Completed $TOOL.\n"

# amass


# findomain


# ffuf


# pureDNS


# crt.sh


echo "\n[-]Scan Complete.\n\nSubdomains are saved in - $DIR/$TOOL.txt"