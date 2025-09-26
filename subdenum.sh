#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

# Include module.sh file
source $SCRIPT_DIR/module.sh

# Show help
show_help() {
    echo -e "${BLUE}Usage:${NC} subdenum <target> [option]\n"
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${YELLOW} blank${NC}\tScan in Normal Mode (Default)"
    echo -e "  ${GREEN} --deep${NC}\tScan in Deep Mode\n"
    echo -e "${BLUE}Example:${NC}"
    echo -e "  ${YELLOW}subdenum ${NC}${GREEN}example.com${NC} \t\t# To run in normal mode"
    echo -e "  ${YELLOW}subdemun ${NC}${GREEN}example.com${NC} ${YELLOW}--deep${NC} \t# To run in deep mode"
}

# --- Main Script ---

# List of required tools
tools=(
    assetfinder jq curl findomain puredns massdns subfinder sublist3r amass ffuf sort sed httpx csvcut awk httpx gowitness
)
check_requirements "${tools[@]}"

# Argument check
if [ $# -eq 0 ]; then
    msg err "No arguments provided."
    show_help
    exit 1
fi

# First argument could be help flag
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        TARGET="$1"
        ;;
esac

# Optional second argument
SCAN_MODE="${2:-}"

# Paths Configuration

CURRENT_PATH=$(pwd)
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"
RESOLVER="$SCRIPT_DIR/resolver.txt"
# OUTPUT_DIR="$HOME/bug_hunting_data/$TARGET/subdomain"
OUTPUT_DIR="$CURRENT_PATH/$TARGET/subdomain"

# Setup
if [ ! -f "$WORDLIST" ]; then
    msg err "Seclist not found at $WORDLIST. Please install it."
    exit 1
fi
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/tools_findings"

# Script Overview
msg header "Script Overview"
echo "$DEVIDER"
msg "" "Task\t: ${GREEN}Subdomain Enumeration${NC}"
msg "" "Target\t: ${GREEN}$TARGET${NC}"
if [ "$SCAN_MODE" == "--deep" ]; then
    msg speacial "Scan\t: " "Deep${NC}"
else
    msg "" "Scan\t: ${GREEN}Fast${NC}"
fi

# Subdomain Enumeration
msg header "Enumerating Subdomains"
echo "$DEVIDER"
run_tool "assetfinder" assetfinder -subs-only "$TARGET"
run_tool "crt" sh -c "curl -s 'https://crt.sh/?q=%25.$TARGET&output=json' | jq -r '.[].name_value'"
run_tool "findomain" findomain -q -t "$TARGET"
run_tool "puredns" puredns bruteforce "$WORDLIST" "$TARGET" -q -r "$RESOLVER"
run_tool "subfinder" subfinder -d "$TARGET" -silent
run_tool "sublist3r" sh -c "sublist3r -d $TARGET -n 2> /dev/null | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u"

# Deep Scan
if [ "$SCAN_MODE" == "deep" ]; then
    run_tool "amass" amass enum -d "$TARGET" -silent -nocolor
    
    msg run "ffuf"
    ffuf -w "$WORDLIST" -u "https://FUZZ.$TARGET" -of json -o "$OUTPUT_DIR/ffuf.json" &> /dev/null
    if [ -f "$OUTPUT_DIR/ffuf.json" ]; then
        jq -r '.results[].url' "$OUTPUT_DIR/ffuf.json" | sed 's|https?://||' > "$OUTPUT_DIR/ffuf.txt"
        rm "$OUTPUT_DIR/ffuf.json"
        msg status "Finished"
    else
        msg fail "Status\t:${NC} ${RED}Error on ffuf${NC}."
    fi
fi

# Further Procecing
msg header "Processing Subdomains"
echo $DEVIDER

# Marging Unique Subdomains
msg running "Merging unique subdomains into all.txt"
cat "$OUTPUT_DIR"/tools_findings/*.txt | sed -E 's#https?://##g' | sort -u > "$OUTPUT_DIR/all.txt"

# Check Subdomains Status
msg running "Checking Subdomains Status - by httpx"
cat "$OUTPUT_DIR/all.txt" | httpx -o "$OUTPUT_DIR/subdomains.csv" -csv &> /dev/null
if [ -f "$OUTPUT_DIR/subdomains.csv" ]; then
    # Removing extra columns
    msg running "Removing extra columns form CSV file - by csvcut"
    csvcut -c url,status_code,location,title,path,content_type,webserver,tech,cname,host,a,aaaa,resolvers "$OUTPUT_DIR/subdomains.csv" > "$OUTPUT_DIR/temp.csv" && mv "$OUTPUT_DIR/temp.csv" "$OUTPUT_DIR/subdomains.csv"

    # Separating alive & dead Subdomains
    msg running "Separating alive & dead Subdomains - by awk"
    # Separate alive
    awk -F',' 'NR>1 {if ($11 != 404) print $1}' $OUTPUT_DIR/subdomains.csv > $OUTPUT_DIR/alive.txt
    # Separate 404
    awk -F',' 'NR>1 {if ($11 == 404) print $1}' $OUTPUT_DIR/subdomains.csv > $OUTPUT_DIR/404.txt
fi

# Take Screenshot
msg running "Taking screenshot of all alive subdomains - by gowitness"
cd $OUTPUT_DIR && gowitness scan file -f ./alive.txt --threads 10 --write-db --screenshot-fullpage --delay 3 --save-content --quiet
cd ..

# Final Summary
msg header "Final Report"
echo "$DEVIDER"
TOTAL_SUBS=$(wc -l < "$OUTPUT_DIR/all.txt")
msg warn "Output Path\t: ${YELLOW}$OUTPUT_DIR${NC}"
msg speacial "Total Found\t: " "$TOTAL_SUBS unique subdomains"
