#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

# Include module.sh file
source $SCRIPT_DIR/module.sh

set -euo pipefail

# Tool info
TOOL_NAME="subdenum"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/subdenum.sh"
ALIAS_LINE="alias $TOOL_NAME='$SCRIPT_PATH'"

# ----------[Helper functions]----------

# Check if alias exists in bashrc
alias_exists() {
    grep -Fxq "$ALIAS_LINE" "$HOME/.bashrc"
}

# Install the alias
install_tool() {
    # List of required tools
    check_requirements "${TOOLS[@]}"

    # Download Wordlist
    WORD1_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/DNS/subdomains-top1million-110000.txt"
    WORD2_URL="https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/DNS/subdomains-top1million-5000.txt"
    DEST1="$SCRIPT_DIR/seclists-subdomains-top1million-110000.txt"
    DEST2="$SCRIPT_DIR/seclists-subdomains-top1million-5000.txt"

    # Ensure wordlists exist in SCRIPT_DIR; download missing ones
    if [ -f "$DEST1" ] && [ -f "$DEST2" ]; then
        echo -e "${YELLOW}[i] Wordlists already present in $SCRIPT_DIR${NC}"
    else
        echo -e "${YELLOW}[i] Downloading missing wordlists to $SCRIPT_DIR${NC}"
        # Download first wordlist if missing
        if [ ! -f "$DEST1" ]; then
            curl -fsSL "$WORD1_URL" -o "$DEST1.tmp" && mv "$DEST1.tmp" "$DEST1" || { echo -e "${RED}[X] Failed to download $WORD1_URL${NC}"; exit 1; }
        fi
        # Download second wordlist if missing
        if [ ! -f "$DEST2" ]; then
            curl -fsSL "$WORD2_URL" -o "$DEST2.tmp" && mv "$DEST2.tmp" "$DEST2" || { echo -e "${RED}[X] Failed to download $WORD2_URL${NC}"; exit 1; }
        fi
        echo -e "${GREEN}[+] Wordlists downloaded${NC}"
    fi
    
    # Make alias on .bashrc
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

# ----------[Argument parsing]----------
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
