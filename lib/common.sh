#!/bin/bash

################################################################################
# Autohunt - Common Library
# Provides common functions for all subtools
# Author: Security Team
# Version: 2.0
################################################################################

# ----------[Core Framework Version]----------
readonly AUTOHUNT_VERSION="1.0.0"

# ----------[Color Definitions]----------
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[1;34m'
readonly CYAN='\033[1;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'
readonly BOLD_YELLOW='\033[1;33m'

# ----------[Logging Levels]----------
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Global log level (can be overridden)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# ----------[Formatting]----------
readonly DIVIDER="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
readonly DIVIDER_SHORT="────────────────────────────────────────────────────────"

# Function to generate divider based on terminal width
get_divider() {
    local char="${1:--}"
    local width=$(tput cols 2>/dev/null || echo 80)
    # Create the divider by repeating the character
    for ((i=0; i<width; i++)); do printf "%s" "$char"; done
}

# Function to generate short divider (for headers)
get_header_divider() {
    local char="${1:-=}"
    local width=$(tput cols 2>/dev/null || echo 80)
    # Subtract 2 for arrow and space in header
    # width=$((width > 2 ? width - 2 : width))
    for ((i=0; i<width; i++)); do printf "%s" "$char"; done
}

# ----------[Enhanced Message Function]----------
msg() {
    local type=$1
    local message=${2:-}
    local detail=${3:-}
    
    case "$type" in
        header)     printf "\n${CYAN}▶ ${BOLD_YELLOW}$message${NC}\n${CYAN}$(get_header_divider)${NC}\n" ;;
        ok|success) printf "${GREEN}[✓]${NC} $message\n" ;;
        info)       printf "${BLUE}[i]${NC} $message\n" ;;
        warn)       printf "${YELLOW}[!]${NC} $message\n" ;;
        err|error)  printf "${RED}[✗]${NC} Error: $message\n" >&2 ;;
        running)    printf "${BLUE}[▶]${NC} Running: ${CYAN}$message${NC}\n" ;;
        done)       printf "${GREEN}[✓]${NC} Done: $message\n" ;;
        speacial)   printf "${CYAN}[+]${NC} $message${CYAN}${detail}${NC}\n" ;;
        divider)    printf "${CYAN}$(get_divider)${NC}\n" ;;
        *)          printf "${BLUE}[-]${NC} $message\n" ;;
    esac
}

# ----------[Logging Functions]----------
log_debug() {
    [ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ] && printf "${BLUE}[DEBUG]${NC} $*\n" >&2 || true
}

log_info() {
    [ $LOG_LEVEL -le $LOG_LEVEL_INFO ] && printf "${BLUE}[INFO]${NC} $*\n" >&2 || true
}

log_warn() {
    [ $LOG_LEVEL -le $LOG_LEVEL_WARN ] && printf "${YELLOW}[WARN]${NC} $*\n" >&2 || true
}

log_error() {
    [ $LOG_LEVEL -le $LOG_LEVEL_ERROR ] && printf "${RED}[ERROR]${NC} $*\n" >&2 || true
}

# ----------[Requirement Checking]----------
check_requirements() {
    local missing_tools=0
    local missing_list=""
    
    # First pass: silently check for missing tools
    for tool in "$@"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_list="$missing_list $tool"
            ((missing_tools++))
        fi
    done
    
    # If all tools are installed, show one-line success
    if [ "$missing_tools" -eq 0 ]; then
        msg ok "All required tools are installed"
        return 0
    fi
    
    # If something is missing, show detailed output
    msg header "Checking Requirements"
    for tool in "$@"; do
        if ! command -v "$tool" &> /dev/null; then
            msg err "$tool is not installed"
        else
            msg ok "$tool is installed"
        fi
    done
    
    msg error "Missing $missing_tools tool(s). Please install them before proceeding."
    return 1
}

# ----------[File Operations]----------
ensure_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        msg info "Creating directory: $dir"
        mkdir -p "$dir" || { msg error "Failed to create directory: $dir"; return 1; }
    fi
}

ensure_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        msg error "Required file not found: $file"
        return 1
    fi
}

# ----------[Execution Functions]----------
run_cmd() {
    local tool_name=$1
    local output_file=$2
    shift 2  # Remove tool_name and output_file from arguments
    
    msg running "$tool_name"
    if "$@" > "$output_file" 2>&1; then
        if [ -s "$output_file" ]; then
            local line_count
            line_count=$(wc -l < "$output_file")
            msg ok "$tool_name found: ${YELLOW}${line_count// /} items${NC}"
        else
            msg warn "$tool_name: No results"
        fi
        return 0
    else
        msg error "$tool_name execution failed"
        return 1
    fi
}

# ----------[String Processing]----------
normalize_domain() {
    tr '[:upper:]' '[:lower:]' | sed -E 's#https?://##; s#/.*##'
}

filter_by_domain() {
    local target=$1
    tr '[:upper:]' '[:lower:]' | sed -E 's#https?://##; s#/.*##' | sort -u | grep -E "\.${target}$" || true
}

# ----------[Progress Tracking]----------
show_progress() {
    local current=$1
    local total=$2
    local label=$3
    
    if [ "$total" -gt 0 ]; then
        local percent=$((current * 100 / total))
        printf "\r${BLUE}[%3d%%]${NC} $label ($current/$total)" "$percent"
    fi
}

# ----------[Output Formatting]----------
print_separator() {
    printf "${DIVIDER_SHORT}\n"
}

print_header() {
    local title=$1
    printf "\n${CYAN}${DIVIDER}${NC}\n"
    printf "${YELLOW}${title}${NC}\n"
    printf "${CYAN}${DIVIDER}${NC}\n"
}

# ----------[Error Handling]----------
exit_on_error() {
    local exit_code=$?
    local line_number=$1
    if [ $exit_code -ne 0 ]; then
        msg error "Command failed at line $line_number with exit code $exit_code"
        exit $exit_code
    fi
}

trap 'exit_on_error ${LINENO}' ERR

# ----------[Version Management]----------
get_version() {
    echo "$AUTOHUNT_VERSION"
}

print_version_info() {
    local framework_version=$(get_version)
    printf "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║${NC}              ${YELLOW}Autohunt - Security Automation Framework${NC}\n"
    printf "${CYAN}║${NC}                  ${BLUE}Core Version: v${framework_version}${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

# ----------[Validation Functions]----------
is_valid_domain() {
    local domain=$1
    if [[ $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_args() {
    if [ $# -eq 0 ]; then
        return 1
    fi
    return 0
}

# ----------[Configuration Loading]----------
load_config() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        source "$config_file"
        msg ok "Configuration loaded from: $config_file"
        return 0
    else
        msg warn "Configuration file not found: $config_file"
        return 1
    fi
}

# ----------[Performance Functions]----------
start_timer() {
    echo $SECONDS
}

get_elapsed_time() {
    local start=$1
    echo $((SECONDS - start))
}

print_execution_time() {
    local start=$1
    local elapsed=$(get_elapsed_time "$start")
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    
    printf "${GREEN}Execution Time: ${YELLOW}"
    [ $hours -gt 0 ] && printf "%dh " $hours
    [ $minutes -gt 0 ] && printf "%dm " $minutes
    printf "%ds${NC}\n" $seconds
}

# ----------[Export Functions]----------
export -f msg log_debug log_info log_warn log_error
export -f check_requirements ensure_dir ensure_file
export -f run_cmd normalize_domain filter_by_domain
export -f show_progress print_separator print_header
export -f is_valid_domain validate_args
export -f load_config start_timer get_elapsed_time print_execution_time
export -f get_version print_version_info
export -f get_divider get_header_divider
export AUTOHUNT_VERSION
