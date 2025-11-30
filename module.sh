#!/bin/bash

# ----------[Common Variables]----------

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
SPEACIAL='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Common String Variables
DEVIDER="------------------------------------------------------------"

# Requirement Tools
TOOLS=(
    assetfinder jq curl findomain puredns massdns subfinder sublist3r amass ffuf sort sed httpx csvcut awk httpx gowitness
)

# ----------[Functions]----------

# Function to print messages
msg() {
    case "$1" in
        header)  echo -e "\n${YELLOW}[+] $2${NC}" ;;
        ok)      echo -e "${GREEN}[+] $2${NC}" ;;
        running) echo -e "${BLUE}[+] $2${NC}" ;;
        speacial)echo -e "${SPEACIAL}[+]${NC} $2${SPEACIAL}$3${NC}" ;;
        err)     echo -e "${RED}[-] Error:${NC} $2" >&2 ;;
        fail)    echo -e "${RED}[!]${NC} $2${NC}" >&2 ;;
        run)     echo -e "${BLUE}[+]${NC} Running\t: ${BLUE}$2${NC}" ;;
        warn)    echo -e "${YELLOW}[+]${NC} $2${NC}" ;;
        info)    echo -e "${YELLOW}[i]${NC} $2${NC}" ;;
        status)  echo -e "${GREEN}[+]${NC} Status\t: ${GREEN}$2${NC}" ;;
        *)       echo -e "${BLUE}[-]${NC} $2${NC}" ;;
    esac
}

# Function to checking requirement tools
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
    local output_file="$OUTPUT_DIR/tools_findings/$tool_name.txt"
    shift # Remove tool_name from arguments
    
    msg run "$tool_name"
    if "$@" > "$output_file"; then
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

# Filter Subdomains
filter_subdomain() {
    local target=$1
    local input_file=$2
    local output_file=$3
    cat $input_file | tr '[:upper:]' '[:lower:]' | sed -E 's#https?://##; s#/.*##' | sort -u | grep -E "\.${target}$" > $output_file
}