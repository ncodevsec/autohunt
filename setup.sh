#!/bin/bash

################################################################################
# Autohunt - Unified Setup Manager
# Handles installation and uninstallation of all subtools
# Version: 1.0.0
################################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Source common library
source "${SCRIPT_DIR}/lib/common.sh"

# Tool metadata
readonly TOOL_NAME="autohunt"
readonly MAIN_SCRIPT="${SCRIPT_DIR}/autohunt.sh"
readonly SUBDENUM_SCRIPT="${SCRIPT_DIR}/subtools/subdenum/subdenum.sh"
readonly COMPLETION_SCRIPT="${SCRIPT_DIR}/autohunt.bash_completion"

# ----------[Installation Utilities]----------
install_go_tools() {
    msg header "Installing Go-based Tools"
    
    local go_tools=(
        "github.com/tomnomnom/assetfinder@latest"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/ffuf/ffuf@latest"
        "github.com/d3mondev/puredns/v2@latest"
        "github.com/sensepost/gowitness@latest"
        "github.com/owasp-amass/amass/v4/cmd/amass@latest"
    )
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        msg warn "Go is not installed. Installing Go..."
        install_golang
    fi
    
    for tool in "${go_tools[@]}"; do
        msg running "Installing $tool"
        if go install "$tool" 2>&1 | tail -1; then
            msg ok "Installed: $tool"
        else
            msg warn "Failed or skipped: $tool"
        fi
    done
}

install_golang() {
    msg header "Installing Go Language"
    
    # Detect OS and architecture
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
    esac
    
    # Get latest Go version
    local latest=$(curl -s https://go.dev/VERSION?m=text | head -n 1 | tr -d '\r')
    
    msg running "Downloading $latest for ${OS}-${ARCH}"
    
    local download_url="https://go.dev/dl/${latest}.${OS}-${ARCH}.tar.gz"
    
    if curl -fsSL "$download_url" -o /tmp/go.tar.gz; then
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        
        # Update bashrc
        grep -qxF 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc || \
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        grep -qxF 'export GOPATH=$HOME/go' ~/.bashrc || \
            echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        grep -qxF 'export PATH=$PATH:$GOPATH/bin' ~/.bashrc || \
            echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
        
        # Load environment
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
        
        msg ok "Go installed successfully: $(go version)"
    else
        msg error "Failed to download Go"
        return 1
    fi
}

install_system_tools() {
    msg header "Installing System Tools"
    
    # Detect package manager
    local pkg_manager=""
    local install_cmd=""
    
    if command -v apt-get &> /dev/null; then
        pkg_manager="apt"
        install_cmd="sudo apt-get install -y"
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
        install_cmd="sudo yum install -y"
    elif command -v brew &> /dev/null; then
        pkg_manager="brew"
        install_cmd="brew install"
    else
        msg error "Could not detect package manager"
        return 1
    fi
    
    msg info "Detected package manager: $pkg_manager"
    
    # Update package lists
    if [ "$pkg_manager" == "apt" ]; then
        msg running "Updating package lists"
        sudo apt-get update -qq || msg warn "Failed to update package lists"
    fi
    
    # Install packages
    local packages=("curl" "jq" "git" "build-essential" "python3-pip")
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            msg running "Installing $pkg"
            $install_cmd "$pkg" 2>&1 | tail -1 || msg warn "Failed to install $pkg"
        else
            msg ok "$pkg is already installed"
        fi
    done
}

install_python_tools() {
    msg header "Installing Python Tools"
    
    # Install pipx if not present
    if ! command -v pipx &> /dev/null; then
        msg running "Installing pipx"
        python3 -m pip install --user pipx
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Install Python tools
    msg running "Installing csvkit"
    pipx install csvkit 2>&1 | tail -1 || msg warn "Failed to install csvkit"
    
    msg running "Installing sublist3r"
    pipx install sublist3r 2>&1 | tail -1 || msg warn "Failed to install sublist3r"
}

install_massdns() {
    msg header "Installing MassDNS"
    
    if ! command -v massdns &> /dev/null; then
        msg running "Building MassDNS from source"
        
        local tmpdir=$(mktemp -d)
        cd "$tmpdir"
        
        if git clone --depth 1 https://github.com/blechschmidt/massdns.git &> /dev/null; then
            cd massdns
            if make &> /dev/null; then
                sudo cp bin/massdns /usr/local/bin/ && msg ok "MassDNS installed"
            else
                msg warn "Failed to build MassDNS"
            fi
            cd /
            rm -rf "$tmpdir"
        else
            msg warn "Failed to clone MassDNS repository"
        fi
    else
        msg ok "MassDNS is already installed"
    fi
}

install_findomain() {
    msg header "Installing Findomain"
    
    if ! command -v findomain &> /dev/null; then
        msg running "Installing Findomain"
        
        # Try downloading precompiled binary
        local download_url="https://github.com/Findomain/findomain/releases/latest/download/findomain-linux"
        
        if curl -fsSL "$download_url" -o /tmp/findomain; then
            chmod +x /tmp/findomain
            sudo mv /tmp/findomain /usr/local/bin/
            msg ok "Findomain installed"
        else
            msg warn "Failed to install Findomain"
        fi
    else
        msg ok "Findomain is already installed"
    fi
}

download_wordlists() {
    msg header "Downloading Wordlists"
    
    local wordlist_dir="${SCRIPT_DIR}/subtools/subdenum/wordlists"
    ensure_dir "$wordlist_dir"
    
    # Wordlist URLs
    local url_110k="https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/DNS/subdomains-top1million-110000.txt"
    local url_5k="https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/DNS/subdomains-top1million-5000.txt"
    
    local dest_110k="${wordlist_dir}/seclists-subdomains-top1million-110000.txt"
    local dest_5k="${wordlist_dir}/seclists-subdomains-top1million-5000.txt"
    
    # Download 110K wordlist
    if [ ! -f "$dest_110k" ]; then
        msg running "Downloading subdomains-top1million-110000.txt (large wordlist)"
        if curl -fsSL "$url_110k" -o "$dest_110k"; then
            msg ok "Downloaded: seclists-subdomains-top1million-110000.txt"
        else
            msg error "Failed to download 110K wordlist"
            return 1
        fi
    else
        msg ok "Wordlist already present: seclists-subdomains-top1million-110000.txt"
    fi
    
    # Download 5K wordlist
    if [ ! -f "$dest_5k" ]; then
        msg running "Downloading subdomains-top1million-5000.txt (fast wordlist)"
        if curl -fsSL "$url_5k" -o "$dest_5k"; then
            msg ok "Downloaded: seclists-subdomains-top1million-5000.txt"
        else
            msg error "Failed to download 5K wordlist"
            return 1
        fi
    else
        msg ok "Wordlist already present: seclists-subdomains-top1million-5000.txt"
    fi
}

# ----------[Alias Management]----------
add_alias() {
    local alias_line="alias autohunt='${MAIN_SCRIPT}'"
    
    if grep -Fxq "$alias_line" ~/.bashrc 2>/dev/null; then
        msg info "Alias already exists in ~/.bashrc"
    else
        echo "$alias_line" >> ~/.bashrc
        msg ok "Added alias to ~/.bashrc"
    fi
    
    # Add subdenum alias
    local subdenum_alias="alias subdenum='${SUBDENUM_SCRIPT}'"
    if grep -Fxq "$subdenum_alias" ~/.bashrc 2>/dev/null; then
        msg info "Subdenum alias already exists in ~/.bashrc"
    else
        echo "$subdenum_alias" >> ~/.bashrc
        msg ok "Added subdenum alias to ~/.bashrc"
    fi
}

# ----------[Completion Management]----------
install_completion() {
    msg header "Installing Bash Completion"
    
    # Create completion directory if it doesn't exist
    local completion_dir="${HOME}/.bash_completion.d"
    if [ ! -d "$completion_dir" ]; then
        mkdir -p "$completion_dir"
        msg ok "Created completion directory: $completion_dir"
    fi
    
    # Copy completion script
    if [ -f "$COMPLETION_SCRIPT" ]; then
        cp "$COMPLETION_SCRIPT" "$completion_dir/autohunt"
        chmod 644 "$completion_dir/autohunt"
        msg ok "Installed bash completion to $completion_dir/autohunt"
        
        # Source the completion in bashrc if not already there
        local completion_source="[ -d \"\$HOME/.bash_completion.d\" ] && for f in \$HOME/.bash_completion.d/*; do [ -f \"\$f\" ] && source \"\$f\"; done"
        if ! grep -Fxq "$completion_source" ~/.bashrc 2>/dev/null; then
            echo "" >> ~/.bashrc
            echo "# Load bash completions" >> ~/.bashrc
            echo "$completion_source" >> ~/.bashrc
            msg ok "Added completion loader to ~/.bashrc"
        fi
    else
        msg warn "Completion script not found: $COMPLETION_SCRIPT"
    fi
}

remove_completion() {
    local completion_dir="${HOME}/.bash_completion.d"
    if [ -f "$completion_dir/autohunt" ]; then
        rm -f "$completion_dir/autohunt"
        msg ok "Removed bash completion"
    fi
}

remove_alias() {
    local alias_line="alias autohunt='${MAIN_SCRIPT}'"
    local subdenum_alias="alias subdenum='${SUBDENUM_SCRIPT}'"
    
    if grep -Fxq "$alias_line" ~/.bashrc 2>/dev/null; then
        sed -i "\|$alias_line|d" ~/.bashrc
        msg ok "Removed autohunt alias from ~/.bashrc"
    fi
    
    if grep -Fxq "$subdenum_alias" ~/.bashrc 2>/dev/null; then
        sed -i "\|$subdenum_alias|d" ~/.bashrc
        msg ok "Removed subdenum alias from ~/.bashrc"
    fi
}

# ----------[Installation & Uninstallation]----------
install_tool() {
    msg header "Installing Autohunt Framework"
    
    # Make scripts executable
    chmod +x "${MAIN_SCRIPT}"
    chmod +x "${SUBDENUM_SCRIPT}"
    msg ok "Scripts made executable"
    
    # Install system tools
    install_system_tools
    
    # Install Python tools
    install_python_tools
    
    # Install massdns and findomain
    install_massdns
    install_findomain
    
    # Install Go tools
    install_go_tools
    
    # Download wordlists
    download_wordlists
    
    # Add aliases
    add_alias
    
    # Install bash completion
    install_completion
    
    msg header "Installation Complete!"
    printf "${GREEN}✓ Autohunt has been installed successfully!${NC}\n"
    printf "\n"
    printf "${YELLOW}Next steps:${NC}\n"
    printf "1. Reload your shell configuration: ${CYAN}source ~/.bashrc${NC}\n"
    printf "2. Test the installation: ${CYAN}autohunt --version${NC}\n"
    printf "3. List available tools: ${CYAN}autohunt list${NC}\n"
    printf "4. Start enumeration: ${CYAN}autohunt subdenum example.com${NC}\n"
    printf "\n"
    printf "${BLUE}For help:${NC}\n"
    printf "  ${CYAN}autohunt --help${NC}          Show main help\n"
    printf "  ${CYAN}autohunt subdenum --help${NC}  Show subdenum help\n"
}

uninstall_tool() {
    msg header "Uninstalling Autohunt Framework"
    
    # Remove aliases
    remove_alias
    
    # Remove completion
    remove_completion
    
    msg ok "Autohunt has been uninstalled"
    msg info "Reload your shell: ${CYAN}source ~/.bashrc${NC}"
}

# ----------[Help]----------
show_help() {
    printf "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║${NC}          ${YELLOW}Autohunt Setup Manager${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
    printf "${BLUE}USAGE:${NC}\n"
    printf "  ${GREEN}autohunt setup${NC} [OPTION]\n"
    printf "  ${GREEN}./setup.sh${NC} [OPTION]\n"
    printf "\n"
    printf "${BLUE}OPTIONS:${NC}\n"
    printf "  ${GREEN}-i${NC}, ${GREEN}--install${NC}    Install all tools and dependencies\n"
    printf "  ${GREEN}-r${NC}, ${GREEN}--remove${NC}     Uninstall and remove aliases\n"
    printf "  ${GREEN}-h${NC}, ${GREEN}--help${NC}       Show this help message\n"
    printf "\n"
    printf "${BLUE}FEATURES:${NC}\n"
    printf "  ✓ Detects and uses your system package manager (apt, yum, brew)\n"
    printf "  ✓ Installs all required tools and dependencies\n"
    printf "  ✓ Downloads necessary wordlists\n"
    printf "  ✓ Creates convenient aliases\n"
    printf "  ✓ Works on Linux and macOS\n"
    printf "\n"
    printf "${BLUE}REQUIREMENTS:${NC}\n"
    printf "  • sudo access (for system package installation)\n"
    printf "  • Internet connection (for downloading tools and wordlists)\n"
    printf "  • Linux or macOS\n"
    printf "\n"
    printf "${BLUE}EXAMPLES:${NC}\n"
    printf "  ${YELLOW}./setup.sh --install${NC}       Install Autohunt\n"
    printf "  ${YELLOW}autohunt setup -i${NC}           Same, using the main tool\n"
    printf "  ${YELLOW}./setup.sh --remove${NC}        Uninstall Autohunt\n"
}

# ----------[Main]----------
main() {
    local action="${1:-}"
    
    case "$action" in
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
            msg error "Invalid option: $action"
            show_help
            exit 1
            ;;
    esac
}

# Execute
main "$@"
