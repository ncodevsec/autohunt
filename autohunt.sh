#!/bin/bash

################################################################################
# Autohunt - Main Entry Point
# Professional Automation Tool for Security Research
# Version: 1.0.0
# Description: Modular framework for chaining security subtools
################################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Source common library
source "${SCRIPT_DIR}/lib/common.sh"

# Tool metadata
readonly TOOL_NAME="autohunt"
readonly TOOL_AUTHOR="Security Team"

# ----------[Help & Usage]----------
show_help() {
    printf "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║${NC}              ${YELLOW}Autohunt - Security Automation Framework${NC}\n"
    printf "${CYAN}║${NC}                      ${BLUE}v${AUTOHUNT_VERSION}${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
    printf "${BLUE}USAGE:${NC}\n"
    printf "  ${GREEN}autohunt${NC} [COMMAND] [OPTIONS]\n"
    printf "\n"
    printf "${BLUE}COMMANDS:${NC}\n"
    printf "  ${GREEN}subdenum${NC} <domain> [--deep]    Run subdomain enumeration\n"
    printf "  ${GREEN}setup${NC} [--install|--remove]    Manage tool installation\n"
    printf "  ${GREEN}list${NC}                          List available subtools\n"
    printf "  ${GREEN}version${NC}                       Show version information\n"
    printf "  ${GREEN}help${NC}                          Show this help message\n"
    printf "\n"
    printf "${BLUE}EXAMPLES:${NC}\n"
    printf "  ${YELLOW}autohunt subdenum example.com${NC}              # Fast scan\n"
    printf "  ${YELLOW}autohunt subdenum example.com --deep${NC}       # Deep scan\n"
    printf "  ${YELLOW}autohunt setup --install${NC}                    # Install all tools\n"
    printf "  ${YELLOW}autohunt list${NC}                              # List subtools\n"
    printf "\n"
    printf "${BLUE}DOCUMENTATION:${NC}\n"
    printf "  For detailed documentation, see: ${YELLOW}README.md${NC}\n"
}

show_version() {
    print_version_info
    printf "\n${BLUE}INSTALLED SUBTOOLS:${NC}\n"
    
    local subtools_dir="${SCRIPT_DIR}/subtools"
    if [ ! -d "$subtools_dir" ]; then
        msg warn "No subtools directory found"
        return 1
    fi
    
    local count=0
    for subtool in "$subtools_dir"/*; do
        if [ -d "$subtool" ]; then
            local name=$(basename "$subtool")
            local main_script="$subtool/${name}.sh"
            
            if [ -f "$main_script" ]; then
                # Try to extract MODULE_VERSION from script
                local version=$(grep -m1 "^readonly MODULE_VERSION=" "$main_script" | sed 's/.*readonly MODULE_VERSION="\([^"]*\)".*/\1/' || echo "unknown")
                # Try to extract Description from script
                local description=$(grep -m1 "# Description:" "$main_script" | sed 's/.*# Description: //' || echo "")
                printf "  ${GREEN}%-15s${NC} v%-10s %s\n" "$name" "$version" "$description"
                ((count++))
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        msg warn "No subtools found"
        return 1
    fi
    
    printf "\n${BLUE}Author:${NC} ${TOOL_AUTHOR}\n"
    printf "${BLUE}License:${NC} MIT\n"
}

# ----------[Subtools Management]----------
list_subtools() {
    msg header "Available Subtools"
    
    local subtools_dir="${SCRIPT_DIR}/subtools"
    if [ ! -d "$subtools_dir" ]; then
        msg warn "No subtools directory found"
        return 1
    fi
    
    local count=0
    for subtool in "$subtools_dir"/*; do
        if [ -d "$subtool" ]; then
            local name=$(basename "$subtool")
            local main_script="$subtool/${name}.sh"
            
            if [ -f "$main_script" ]; then
                # Try to extract description from script
                local description=$(grep -m1 "# Description:" "$main_script" | sed 's/.*# Description: //' || echo "")
                printf "  ${GREEN}%-20s${NC} %s\n" "$name" "$description"
                ((count++))
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        msg warn "No subtools found"
        return 1
    fi
    
    msg ok "$count subtool(s) available"
    return 0
}

# ----------[Subtool Routing]----------
run_subtool() {
    local subtool_name=$1
    shift  # Remove subtool name from arguments
    
    local subtool_path="${SCRIPT_DIR}/subtools/${subtool_name}/${subtool_name}.sh"
    
    if [ ! -f "$subtool_path" ]; then
        msg error "Subtool not found: $subtool_name"
        msg info "Run '${GREEN}${TOOL_NAME} list${NC}' to see available subtools"
        return 1
    fi
    
    # Execute the subtool with remaining arguments
    bash "$subtool_path" "$@"
}

# ----------[Setup Management]----------
setup_tool() {
    local action=${1:-}
    local setup_script="${SCRIPT_DIR}/setup.sh"
    
    if [ ! -f "$setup_script" ]; then
        msg error "Setup script not found: $setup_script"
        return 1
    fi
    
    bash "$setup_script" "$action"
}

# ----------[Main Argument Parsing]----------
main() {
    local command=${1:-}
    
    # Handle no arguments
    if [ -z "$command" ]; then
        msg error "No command provided"
        show_help
        exit 1
    fi
    
    case "$command" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        -v|--version|version)
            show_version
            exit 0
            ;;
        list)
            list_subtools
            exit $?
            ;;
        setup)
            shift
            setup_tool "$@"
            exit $?
            ;;
        subdenum)
            shift
            run_subtool "subdenum" "$@"
            exit $?
            ;;
        *)
            # Check if it's a registered subtool
            if [ -d "${SCRIPT_DIR}/subtools/${command}" ]; then
                shift
                run_subtool "$command" "$@"
                exit $?
            else
                msg error "Unknown command: $command"
                msg info "Run '${GREEN}${TOOL_NAME} help${NC}' for usage information"
                exit 1
            fi
            ;;
    esac
}

# Execute main function
main "$@"
