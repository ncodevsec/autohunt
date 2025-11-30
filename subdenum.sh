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

# ----------[ Main Script ]----------

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

# Check requirement tools (Installed or not)
check_requirements "${TOOLS[@]}"

# ----------> Paths Configuration

# Current Path
CURRENT_PATH=$(pwd)

# DNS Resolver
RESOLVER="$SCRIPT_DIR/resolver.txt"

# Wordlist
if [ "$SCAN_MODE" == "--deep" ]; then
    WORDLIST="$SCRIPT_DIR/seclists-subdomains-top1million-110000.txt"
else
    WORDLIST="$SCRIPT_DIR/seclists-subdomains-top1million-5000.txt"
fi

# Output Directory
# OUTPUT_DIR="$HOME/bug_hunting_data/$TARGET/subdomain"
OUTPUT_DIR="$CURRENT_PATH/$TARGET/subdomain"
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
if [ "$SCAN_MODE" == "--deep" ]; then
    # Amass
    run_tool "amass" amass enum -d "$TARGET"

    # FFUF
    msg run "ffuf"
    FFUFjson="$OUTPUT_DIR/tools_findings/ffuf.json" 
    FFUFtxt="$OUTPUT_DIR/tools_findings/ffuf.txt" 
    ffuf -w "$WORDLIST" -u "https://FUZZ.$TARGET" -of json -o "$FFUFjson" &> /dev/null
    if [ -f "$FFUFjson" ]; then
        jq -r '.results[].url' "$FFUFjson" | sed 's|https?://||' > "$FFUFtxt"
        rm "$FFUFjson"
        if [ -s "$FFUFtxt" ]; then
            line_count=$(wc -l < "$FFUFtxt")
            msg info "Found\t: ${YELLOW}${line_count// /} items${NC}"
        fi
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
filter_subdomain $TARGET "$OUTPUT_DIR/tools_findings/*.txt" $OUTPUT_DIR/all.txt

# Check Subdomains Status
msg running "Checking Subdomains Status - by httpx"
cat "$OUTPUT_DIR/all.txt" | httpx -o "$OUTPUT_DIR/subdomains.csv" -csv &> /dev/null
if [ -f "$OUTPUT_DIR/subdomains.csv" ]; then
    # Removing extra columns
    msg running "Removing extra columns form CSV file - by csvcut"
    csvcut -c status_code,url,location,title,path,content_type,webserver,tech,cname,host,resolvers "$OUTPUT_DIR/subdomains.csv" > "$OUTPUT_DIR/temp.csv" && mv "$OUTPUT_DIR/temp.csv" "$OUTPUT_DIR/subdomains.csv"
    # Separating alive & dead Subdomains
    msg running "Separating alive & dead Subdomains - by awk"
    # Separate alive
    awk -F',' 'NR>1 {if ($1 != 404) print $2}' $OUTPUT_DIR/subdomains.csv > $OUTPUT_DIR/alive.txt
    # Separate 404
    awk -F',' 'NR>1 {if ($1 == 404) print $2}' $OUTPUT_DIR/subdomains.csv > $OUTPUT_DIR/404.txt
fi

# Take Screenshot
ALIVE=$(wc -l < "$OUTPUT_DIR/alive.txt")
msg running "Taking screenshot of all $YELLOW$ALIVE$NC $BLUE alive subdomains - by gowitness"
cd $OUTPUT_DIR && gowitness scan file -f $OUTPUT_DIR/alive.txt --threads 20 --delay 10 --timeout 15 --write-db --save-content --skip-html --quiet
cd ../

# Final Summary
msg header "Final Report"
echo "$DEVIDER"
TOTAL_SUBS=$(wc -l < "$OUTPUT_DIR/all.txt")
msg warn "Output Path\t: ${YELLOW}$OUTPUT_DIR${NC}"
msg speacial "Total Found\t: " "$TOTAL_SUBS unique subdomains"
