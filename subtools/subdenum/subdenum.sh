#!/bin/bash

################################################################################
# Subdenum - Subdomain Enumeration Subtool
# Description: Fast and comprehensive subdomain discovery and live host detection
# Version: 1.0.0
# Usage: subdenum <domain> [--deep]
################################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PARENT_DIR=$(dirname "$SCRIPT_DIR")
ROOT_DIR=$(dirname "$PARENT_DIR")

# Source common library
source "${ROOT_DIR}/lib/common.sh"

# ----------[Module Version]----------
readonly MODULE_VERSION="1.0.0"

get_module_version() {
    echo "$MODULE_VERSION"
}

# ----------[Tool Configuration]----------
# Required tools for subdenum
declare -a REQUIRED_TOOLS=(
    "assetfinder" "jq" "curl" "findomain" "puredns" "massdns"
    "subfinder" "sublist3r" "amass" "ffuf" "sort" "sed"
    "httpx" "csvcut" "awk" "gowitness"
)

# Wordlist URLs
readonly WORDLIST_110K_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/DNS/subdomains-top1million-110000.txt"
readonly WORDLIST_5K_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/DNS/subdomains-top1million-5000.txt"

# ----------[Help & Usage]----------
show_help() {
    printf "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║${NC}           ${YELLOW}Subdenum - Subdomain Enumeration Tool${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
    printf "${BLUE}USAGE:${NC}\n"
    printf "  ${GREEN}subdenum${NC} <domain> [--deep]\n"
    printf "\n"
    printf "${BLUE}OPTIONS:${NC}\n"
    printf "  ${YELLOW}<domain>${NC}        Target domain (required)\n"
    printf "  ${GREEN}--deep${NC}          Enable deep scanning (includes amass & ffuf)\n"
    printf "  ${GREEN}-h, --help${NC}       Show this help message\n"
    printf "\n"
    printf "${BLUE}SCAN MODES:${NC}\n"
    printf "  ${GREEN}Fast Mode (default)${NC}\n"
    printf "    - Assetfinder, crt.sh, Findomain, PureDNS\n"
    printf "    - Subfinder, Sublist3r\n"
    printf "    - Uses smaller wordlist (5,000 subdomains)\n"
    printf "    \n"
    printf "  ${CYAN}Deep Mode (--deep)${NC}\n"
    printf "    - All Fast Mode tools\n"
    printf "    - Amass enumeration\n"
    printf "    - FFUF bruteforce\n"
    printf "    - Uses large wordlist (110,000 subdomains)\n"
    printf "\n"
    printf "${BLUE}FEATURES:${NC}\n"
    printf "  ✓ Multi-source subdomain discovery\n"
    printf "  ✓ Automatic deduplication and filtering\n"
    printf "  ✓ Live host detection with httpx\n"
    printf "  ✓ Screenshot capture with gowitness\n"
    printf "  ✓ Structured output (CSV, TXT, JSON)\n"
    printf "  ✓ Parallel processing for speed\n"
    printf "\n"
    printf "${BLUE}EXAMPLES:${NC}\n"
    printf "  ${YELLOW}subdenum example.com${NC}              # Fast scan\n"
    printf "  ${YELLOW}subdenum example.com --deep${NC}       # Deep scan with all tools\n"
    printf "\n"
    printf "${BLUE}OUTPUT:${NC}\n"
    printf "  Results saved to: ${YELLOW}<domain>/subdomain/${NC}\n"
    printf "  \n"
    printf "  Files generated:\n"
    printf "  - ${GREEN}all.txt${NC}              All found subdomains\n"
    printf "  - ${GREEN}subdomains.csv${NC}       Live hosts with detailed info\n"
    printf "  - ${GREEN}alive.txt${NC}            Live subdomains (non-404)\n"
    printf "  - ${GREEN}404.txt${NC}              Dead subdomains (404 responses)\n"
    printf "  - ${GREEN}tools_findings/${NC}      Individual tool results\n"
    printf "  - ${GREEN}gowitness/${NC}           Screenshots and database\n"
}

# ----------[Initialization]----------
init_environment() {
    local target=$1
    
    # Create output directories
    ensure_dir "${OUTPUT_DIR}"
    ensure_dir "${OUTPUT_DIR}/tools_findings"
    
    msg ok "Environment initialized"
    log_debug "Output directory: $OUTPUT_DIR"
    log_debug "Resolver file: $RESOLVER"
    log_debug "Wordlist: $WORDLIST"
}

# ----------[Tool Execution]----------
run_assetfinder() {
    run_cmd "assetfinder" \
        "${OUTPUT_DIR}/tools_findings/assetfinder.txt" \
        assetfinder -subs-only "$TARGET"
}

run_crtsh() {
    run_cmd "crt.sh" \
        "${OUTPUT_DIR}/tools_findings/crt.txt" \
        bash -c "curl -s 'https://crt.sh/?q=%25.${TARGET}&output=json' | jq -r '.[].name_value' 2>/dev/null || true"
}

run_findomain() {
    run_cmd "findomain" \
        "${OUTPUT_DIR}/tools_findings/findomain.txt" \
        findomain -q -t "$TARGET" 2>/dev/null || true
}

run_puredns() {
    run_cmd "puredns" \
        "${OUTPUT_DIR}/tools_findings/puredns.txt" \
        puredns bruteforce "$WORDLIST" "$TARGET" -q -r "$RESOLVER" 2>/dev/null || true
}

run_subfinder() {
    run_cmd "subfinder" \
        "${OUTPUT_DIR}/tools_findings/subfinder.txt" \
        subfinder -d "$TARGET" -silent 2>/dev/null || true
}

run_sublist3r() {
    run_cmd "sublist3r" \
        "${OUTPUT_DIR}/tools_findings/sublist3r.txt" \
        bash -c "sublist3r -d $TARGET -n 2>/dev/null | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u || true"
}

run_amass() {
    run_cmd "amass" \
        "${OUTPUT_DIR}/tools_findings/amass.txt" \
        amass enum -d "$TARGET" 2>/dev/null || true
}

run_ffuf() {
    local ffuf_json="${OUTPUT_DIR}/tools_findings/ffuf.json"
    local ffuf_txt="${OUTPUT_DIR}/tools_findings/ffuf.txt"
    
    msg running "ffuf"
    if ffuf -w "$WORDLIST" -u "https://FUZZ.${TARGET}" -of json -o "$ffuf_json" &> /dev/null; then
        if [ -f "$ffuf_json" ] && command -v jq &> /dev/null; then
            if jq -r '.results[].url' "$ffuf_json" | sed 's|https?://||' > "$ffuf_txt" 2>/dev/null; then
                rm -f "$ffuf_json"
                if [ -s "$ffuf_txt" ]; then
                    local line_count=$(wc -l < "$ffuf_txt")
                    msg ok "ffuf found: ${YELLOW}${line_count// /} items${NC}"
                else
                    msg warn "ffuf: No results"
                    rm -f "$ffuf_txt"
                fi
            fi
        fi
    else
        msg warn "ffuf execution skipped or failed"
    fi
}

# ----------[Processing Functions]----------
merge_and_filter() {
    msg running "Merging and filtering subdomains"
    
    # Merge all findings
    cat "${OUTPUT_DIR}/tools_findings"/*.txt 2>/dev/null | \
        cat | normalize_domain | filter_by_domain "$TARGET" | sort -u \
        > "${OUTPUT_DIR}/all.txt"
    
    if [ -s "${OUTPUT_DIR}/all.txt" ]; then
        local total=$(wc -l < "${OUTPUT_DIR}/all.txt")
        msg ok "Merged: ${YELLOW}$total unique subdomains${NC}"
    else
        msg warn "No subdomains found"
        touch "${OUTPUT_DIR}/all.txt"
    fi
}

check_live_hosts() {
    msg running "Checking live hosts with httpx"
    
    if [ ! -s "${OUTPUT_DIR}/all.txt" ]; then
        msg warn "No subdomains to check"
        return 0
    fi
    
    if httpx -l "${OUTPUT_DIR}/all.txt" -o "${OUTPUT_DIR}/subdomains.csv" -csv -silent 2>/dev/null; then
        msg ok "Live host detection completed"
        
        # Remove extra columns for cleaner output
        if command -v csvcut &> /dev/null; then
            msg running "Optimizing CSV output"
            if csvcut -c url,status_code,title,location,webserver \
                "${OUTPUT_DIR}/subdomains.csv" > "${OUTPUT_DIR}/subdomains_opt.csv" 2>/dev/null; then
                mv "${OUTPUT_DIR}/subdomains_opt.csv" "${OUTPUT_DIR}/subdomains.csv"
            fi
        fi
        
        # Separate alive and dead
        separate_alive_dead
    else
        msg warn "httpx execution failed"
    fi
}

separate_alive_dead() {
    msg running "Separating alive and dead subdomains"
    
    if [ -f "${OUTPUT_DIR}/subdomains.csv" ]; then
        # Extract alive subdomains (non-404)
        awk -F',' 'NR>1 {if ($2 != 404) print $1}' "${OUTPUT_DIR}/subdomains.csv" | sort -u > "${OUTPUT_DIR}/alive.txt"
        
        # Extract dead subdomains (404)
        awk -F',' 'NR>1 {if ($2 == 404) print $1}' "${OUTPUT_DIR}/subdomains.csv" | sort -u > "${OUTPUT_DIR}/404.txt"
        
        msg ok "Separation completed"
    fi
}

take_screenshots() {
    if [ ! -f "${OUTPUT_DIR}/alive.txt" ] || [ ! -s "${OUTPUT_DIR}/alive.txt" ]; then
        msg warn "No alive subdomains to screenshot"
        return 0
    fi
    
    local alive_count=$(wc -l < "${OUTPUT_DIR}/alive.txt")
    msg running "Taking screenshots of ${YELLOW}$alive_count${NC} alive subdomains"
    
    if command -v gowitness &> /dev/null; then
        cd "${OUTPUT_DIR}" && \
        gowitness scan file -f "${OUTPUT_DIR}/alive.txt" \
            --threads 20 --delay 10 --timeout 15 \
            --write-db --save-content --skip-html --quiet 2>/dev/null || \
        msg warn "Screenshot capture skipped or failed"
        cd - > /dev/null
    else
        msg warn "gowitness not installed, skipping screenshots"
    fi
}

# ----------[Report Generation]----------
generate_report() {
    msg header "Final Report"
    
    local total=$(wc -l < "${OUTPUT_DIR}/all.txt" 2>/dev/null || echo 0)
    local alive=$(wc -l < "${OUTPUT_DIR}/alive.txt" 2>/dev/null || echo 0)
    local dead=$(wc -l < "${OUTPUT_DIR}/404.txt" 2>/dev/null || echo 0)
    
    printf "\n"
    printf "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
    printf "${YELLOW}SUBDOMAIN ENUMERATION RESULTS${NC}\n"
    printf "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
    printf "\n"
    printf "${GREEN}  • Target\t:${NC}\t$TARGET\n"
    printf "${GREEN}  • Scan Mode\t:${NC}\t${SCAN_MODE:-Fast}\n"
    printf "${GREEN}  • Output\t:${NC}\t$OUTPUT_DIR\n"
    printf "\n"
    printf "${BLUE}STATISTICS:${NC}\n"
    printf "${GREEN}  • Total Found\t:${NC}\t$total unique subdomains\n"
    printf "${GREEN}  • Alive Hosts\t:${NC}\t$alive (HTTP/HTTPS responding)\n"
    printf "${GREEN}  • Dead Hosts\t:${NC}\t$dead (404 responses)\n"
    printf "\n"
    printf "${BLUE}OUTPUT FILES:${NC}\n"
    printf "${GREEN}  • all.txt${NC}              All discovered subdomains\n"
    printf "${GREEN}  • alive.txt${NC}            Live subdomains with responses\n"
    printf "${GREEN}  • 404.txt${NC}              Dead subdomains\n"
    printf "${GREEN}  • subdomains.csv${NC}       Detailed host information\n"
    printf "${GREEN}  • tools_findings/${NC}      Individual tool results\n"
    printf "${GREEN}  • screenshot/${NC}          Screenshots & web data\n"
    printf "${GREEN}  • gowitness.sqlite3${NC}    Web Data\n"
    printf "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
    printf "\n"
    printf "${GREEN} Report Command : ${YELLOW}cd ${OUTPUT_DIR} && gowitness report server${NC}\n"
    printf "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

# ----------[Main Execution]----------
main() {
    local start_time=$(start_timer)
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        msg error "No target domain provided"
        show_help
        exit 1
    fi
    
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            TARGET="$1"
            ;;
    esac
    
    # Validate domain
    if ! is_valid_domain "$TARGET"; then
        msg error "Invalid domain format: $TARGET"
        exit 1
    fi
    
    # Parse optional arguments
    SCAN_MODE="Fast"
    [ "${2:-}" == "--deep" ] && SCAN_MODE="Deep"
    
    # Set paths
    readonly RESOLVER="${SCRIPT_DIR}/resolver.txt"
    readonly OUTPUT_DIR="./$TARGET/subdomain"
    
    if [ "$SCAN_MODE" == "Deep" ]; then
        readonly WORDLIST="${SCRIPT_DIR}/wordlists/seclists-subdomains-top1million-110000.txt"
    else
        readonly WORDLIST="${SCRIPT_DIR}/wordlists/seclists-subdomains-top1million-5000.txt"
    fi
    
    # Validate requirements
    if ! check_requirements "${REQUIRED_TOOLS[@]}"; then
        msg error "Please install missing tools before proceeding"
        msg info "Run: ${GREEN}autohunt setup --install${NC}"
        exit 1
    fi
    
    # Validate resolver and wordlists
    if ! ensure_file "$RESOLVER"; then
        exit 1
    fi
    
    if ! ensure_file "$WORDLIST"; then
        msg error "Wordlist not found: $WORDLIST"
        msg info "Run: ${GREEN}autohunt setup --install${NC}"
        exit 1
    fi
    
    # Initialize
    init_environment "$TARGET"
    
    # Display execution info
    msg header "Subdomain Enumeration"
    printf "${CYAN}  • Target\t:${NC}\t$TARGET\n"
    printf "${CYAN}  • Mode\t:${NC}\t$SCAN_MODE\n"
    printf "${CYAN}  • Output\t:${NC}\t$OUTPUT_DIR\n"
    printf "${CYAN}  • Resolver\t:${NC}\t$RESOLVER\n"
    printf "${CYAN}  • Wordlist\t:${NC}\t$WORDLIST\n"
    msg divider
    
    # Phase 1: Subdomain Discovery
    msg header "Phase 1: Subdomain Discovery"
    run_assetfinder
    run_crtsh
    run_findomain
    run_puredns
    run_subfinder
    run_sublist3r
    
    # Phase 2: Deep Scan (optional)
    if [ "$SCAN_MODE" == "Deep" ]; then
        msg header "Phase 2: Deep Scanning"
        run_amass
        run_ffuf
    fi
    
    # Phase 3: Processing
    msg header "Phase 3: Processing"
    merge_and_filter
    check_live_hosts
    take_screenshots
    
    # Generate report
    generate_report
    
    # Show execution time
    local elapsed=$(get_elapsed_time "$start_time")
    print_execution_time "$start_time"
    
    msg ok "Subdomain enumeration completed successfully!"
}

# Execute main function with all arguments
main "$@"
