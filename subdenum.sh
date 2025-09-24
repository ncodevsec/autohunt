#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
SPEACIAL='\033[0;36m'
NC='\033[0m' # No Color

# Common String Variables
DEVIDER="--------------------------------------------------"

# --- Functions ---

# Function to print messages
msg() {
    case "$1" in
        header)  echo -e "${YELLOW}[+] $2${NC}" ;;
        ok)      echo -e "${GREEN}[+] $2${NC}" ;;
        speacial)  echo -e "${SPEACIAL}[+]${NC} $2${SPEACIAL}$3${NC}" ;;
        warn)    echo -e "${YELLOW}[+]${NC} $2${NC}" ;;
        err)     echo -e "${RED}[-] Error:${NC} $2" >&2 ;;
        fail)    echo -e "${RED}[!]${NC} $2${NC}" >&2 ;;
        run)     echo -e "${BLUE}[-]${NC} Running\t: ${BLUE}$2${NC}" ;;
        info)    echo -e "${YELLOW}[i]${NC} $2${NC}" ;;
        status)  echo -e "${GREEN}[+]${NC} Status\t: ${GREEN}$2${NC}" ;;
        *)       echo -e "${BLUE}[-]${NC} $2${NC}" ;;
    esac
}

# Function to check for required tools
check_requirements() {
    msg header "Checking requirements..."
    local missing_tools=0
    for tool in "$@"; do
        if ! command -v "$tool" &> /dev/null; then
            msg err "$tool is not installed. Attempting to install..."
            # NOTE: This assumes a Debian-based system (like Ubuntu) using 'apt'.
            # You may need to change 'apt-get' to your system's package manager (e.g., 'yum', 'pacman', 'brew').
            sudo apt-get install -y "$tool" &> /dev/null
            if ! command -v "$tool" &> /dev/null; then
                msg fail "Failed to install $tool. Please install it manually."
                ((missing_tools++))
            else
                msg ok "Successfully installed $tool."
            fi
        fi
    done
    if [ "$missing_tools" -gt 0 ]; then
        exit 1
    fi
    msg ok "All required tools are installed."
}

# Function to run a command and handle output
run_tool() {
    local tool_name=$1
    local output_file="$OUTPUT_DIR/$tool_name.txt"
    shift # Remove tool_name from arguments

    msg run "$tool_name"
    if "$@" > "$output_file"; then
        msg status "Finished"
        if [ -s "$output_file" ]; then
            local line_count
            line_count=$(wc -l < "$output_file")
            msg info "Found\t: ${YELLOW}${line_count// /} items${NC}"
        fi
    else
        msg fail "Status\t:${NC} ${RED}Error on $tool_name${NC}."
    fi
    sleep 0.2
}

# --- Main Script ---

# Check for target domain
if [ -z "$1" ]; then
    msg err "Target domain not provided."
    echo "Usage: $0 <target_domain> [deep]"
    exit 1
fi

TARGET=$1
SCAN_MODE=$2

# List of required tools
tools=(
    assetfinder jq curl findomain puredns subfinder
    sublist3r amass ffuf sort sed httpx csvcut aquatone
)
check_requirements "${tools[@]}"

# Configuration
WORDLIST="/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="$SCRIPT_DIR/resolver.txt"
OUTPUT_DIR="$HOME/bug_hunting_data/$TARGET/subdomain"

# Setup
if [ ! -f "$WORDLIST" ]; then
    msg err "Seclist not found at $WORDLIST. Please install it."
    exit 1
fi
mkdir -p "$OUTPUT_DIR"

# Script Overview
echo
msg header "Script Overview"
echo "$DEVIDER"
msg "" "Task\t: ${GREEN}Subdomain Enumeration${NC}"
msg "" "Target\t: ${GREEN}$TARGET${NC}"
if [ "$SCAN_MODE" == "deep" ]; then
    msg speacial "Scan\t: " "Deep${NC}"
else
    msg "" "Scan\t: ${GREEN}Fast${NC}"
fi

# Subdomain Enumeration
echo
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

# Merge and Filter
echo
msg header "Merging and Filtering Subdomains"
echo "$DEVIDER"
msg run "sed"
msg run "sort"
cat "$OUTPUT_DIR"/*.txt | sed -E 's#https?://##g' | sort -u > "$OUTPUT_DIR/all.txt"
msg ok "Merged all subdomains into all.txt"

# Check Live Subdomains
echo
msg header "Checking Subdomains Status"
echo "$DEVIDER"
msg run "httpx"
cat "$OUTPUT_DIR/all.txt" | httpx -o "$OUTPUT_DIR/subdomains.csv" -csv &> /dev/null
msg status "Finished"

if [ -f "$OUTPUT_DIR/subdomains.csv" ]; then
    msg run "csvcut"
    csvcut -c url,status_code,location,title,path,content_type,webserver,tech,cname,host,a,aaaa,resolvers "$OUTPUT_DIR/subdomains.csv" > "$OUTPUT_DIR/temp.csv" && mv "$OUTPUT_DIR/temp.csv" "$OUTPUT_DIR/subdomains.csv"
    msg status "Finished"
fi

# Final Summary
echo
msg ok "Subdomain Enumeration Complete"
echo "$DEVIDER"
TOTAL_SUBS=$(wc -l < "$OUTPUT_DIR/all.txt")
msg warn "Output Path\t: ${YELLOW}$OUTPUT_DIR${NC}"
msg speacial "Total Found\t: " "$TOTAL_SUBS unique subdomains"
