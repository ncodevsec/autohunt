#!/usr/bin/env bash
set -euo pipefail

# =========================
# Colors
# =========================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# =========================
# Tool info
# =========================
TOOL_NAME="subdenum"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/subdenum.sh"
ALIAS_LINE="alias $TOOL_NAME='$SCRIPT_PATH'"

# =========================
# Helper functions
# =========================

# Check if alias exists in bashrc
alias_exists() {
    grep -Fxq "$ALIAS_LINE" "$HOME/.bashrc"
}

# Install the alias
install_tool() {
    if alias_exists; then
        echo -e "${YELLOW}[i] Already Installed. Alias exists in ~/.bashrc${NC}"
    else
        chmod +x $SCRIPT_PATH
        echo "$ALIAS_LINE" >> "$HOME/.bashrc"
        echo -e "${GREEN}[+] Installed Successfully! Alias added in ~/.bashrc${NC}"
    fi
    echo -e "${WHITE}[i] You can now run: ${YELLOW}$TOOL_NAME example.com deep${NC} # From anywhere"
}

# Uninstall the alias
uninstall_tool() {
    if alias_exists; then
        chmod -x $SCRIPT_PATH
        sed -i "\|$ALIAS_LINE|d" "$HOME/.bashrc"
        echo -e "${GREEN}[+] Uninstalled Successfully. Alias removed from ~/.bashrc${NC}"
    else
        echo -e "${YELLOW}[i] Not Installed. Alias not found in ~/.bashrc${NC}"
    fi
}

# Show help
show_help() {
    echo -e "${BLUE}Usage:${NC} $0 [option]\n"
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${GREEN}-i${NC} ,${GREEN} --install${NC}\tAdd alias to ~/.bashrc so you can run '$TOOL_NAME' from anywhere"
    echo -e "  ${RED}-r${NC} ,${RED} --remove${NC}\t\tRemove alias from ~/.bashrc"
    echo -e "  ${YELLOW}-h${NC} ,${YELLOW} --help${NC}\t\tShow this help message\n"
    echo -e "${BLUE}Example:${NC}"
    echo -e "  ${YELLOW}$0 ${NC}${GREEN}--install${NC} \t# To install the tool"
    echo -e "  ${YELLOW}$0 ${NC}${RED}--remove${NC} \t# To uninstall the tool"
}

# =========================
# Argument parsing
# =========================
case "${1:-}" in
    -i|--install)
        install_tool
        ;;
    -r|--remove)
        uninstall_tool
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo -e "${RED}[X] Invalid option${NC}"
        show_help
        exit 1
        ;;
esac
