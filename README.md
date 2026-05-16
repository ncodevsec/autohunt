<div align="center">

# 🎯 Autohunt

**Professional Security Automation Framework for Pentesters & Bug Hunters**

[![Bash](https://img.shields.io/badge/Bash-5.1+-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-Supported-FCC624?logo=linux&logoColor=black)](https://www.linux.org/)
[![macOS](https://img.shields.io/badge/macOS-Supported-000000?logo=apple&logoColor=white)](https://www.apple.com/)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-informational)](setup.sh)
[![Modular](https://img.shields.io/badge/Architecture-Modular-brightgreen)](docs/ARCHITECTURE.md)

---

</div>

## 🎯 Overview

Autohunt is a professional-grade security automation framework designed for pentesters and bug bounty hunters. It provides a unified interface for orchestrating multiple specialized security tools, enabling comprehensive reconnaissance workflows with minimal configuration. The modular architecture makes it trivial to chain together attacks and add new capabilities.

## ✨ Features

### Core Framework
- **Modular Architecture** – Easily add new subtools without modifying core code
- **Unified CLI Interface** – Single command to orchestrate multiple security tools
- **Professional Output** – Color-coded, structured, and informative messages
- **Robust Error Handling** – Comprehensive error checking and validation
- **Extensible Design** – Built to scale with future subtools and workflows

### Included Subtools
- **Subdenum** – Fast and comprehensive subdomain enumeration with live host detection

### Subdenum Features
- **Multi-source Discovery** – 8 enumeration sources: `assetfinder`, `crt.sh`, `findomain`, `subfinder`, `sublist3r`, `puredns`, `amass`, `ffuf`
- **Dual-mode Scanning** – Fast mode (2-5 min) or deep mode (15-45 min) with 110K wordlist
- **Live Host Detection** – Identifies responsive hosts using `httpx`
- **Automated Screenshots** – Captures web pages for rapid analysis with `gowitness`
- **Multiple Output Formats** – CSV, TXT, and SQLite database
- **Parallel Processing** – Multi-threaded operations for optimized speed



## 🛠️ Requirements

**System Requirements:**
- Linux or macOS
- `sudo` access (required for installation)
- Internet connection
- 2GB+ free disk space

**Core Dependencies (Auto-installed):**
- `curl`, `jq`, `git`, `build-essential`, `python3-pip`

**Security Tools (Auto-installed):**
- Go-based: `assetfinder`, `subfinder`, `httpx`, `ffuf`, `puredns`, `gowitness`, `amass`
- Python-based: `sublist3r`, `csvkit`
- Other: `massdns`, `findomain`


## 📦 Installation

### Quick Start
```bash
git clone https://github.com/ncodevsec/autohunt.git
cd autohunt
chmod +x setup.sh
./setup.sh --install
source ~/.bashrc
autohunt --version
```

### One-Line Install
```bash
git clone https://github.com/ncodevsec/autohunt.git && cd autohunt && chmod +x setup.sh && ./setup.sh --install && source ~/.bashrc
```

**Troubleshooting Installation:**
- If Go tools aren't found: `export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin && source ~/.bashrc`
- Permission issues: `chmod +x autohunt.sh setup.sh && chmod +x subtools/*/*.sh`
- For detailed manual setup, see [INSTALLATION.md](INSTALLATION.md)

## 🚀 Quick Start

### Fast Mode (Default) – 2-5 minutes
```bash
autohunt subdenum example.com
# or use the alias:
subdenum example.com
```

### Deep Mode – 15-45 minutes
```bash
autohunt subdenum example.com --deep
# or use the alias:
subdenum example.com --deep
```

## 📖 Usage

### Main Command
```bash
autohunt [COMMAND] [OPTIONS]

Commands:
  subdenum <domain> [--deep]    Subdomain enumeration
  list                          List available subtools
  version                       Show version
  help                          Show help
```

### Subdenum Command
```bash
autohunt subdenum <domain> [OPTIONS]

Options:
  <domain>              Target domain (required)
  --deep               Enable deep scanning mode

Examples:
  autohunt subdenum example.com            # Fast scan
  autohunt subdenum example.com --deep     # Deep scan
  subdenum example.com                     # Fast scan (alias)
  subdenum example.com --deep              # Deep scan (alias)
```

## 📁 Output Structure

Results are saved in: `$HOME/bug_hunting_data/<domain>/subdomain/`

```
results/example.com/subdomain/
├── all.txt                      # All discovered subdomains
├── alive.txt                    # Responsive hosts (HTTP 200+)
├── 404.txt                      # Non-responsive hosts
├── subdomains.csv               # CSV with status codes
├── tools_findings/              # Individual tool outputs
│   ├── assetfinder.txt
│   ├── crt.txt
│   ├── findomain.txt
│   ├── puredns.txt
│   ├── subfinder.txt
│   ├── sublist3r.txt
│   ├── amass.txt                # (deep mode only)
│   └── ffuf.txt                 # (deep mode only)
├── gowitness.sqlite3            # Screenshot database
└── screenshots/                 # Web page screenshots
    ├── https---subdomain1-443.jpeg
    ├── https---subdomain2-443.jpeg
    └── ...
```

## 🔍 Understanding the Modes

### Fast Mode (Default)
Best for initial reconnaissance:
- **Duration**: 2-5 minutes
- **Wordlist**: 5,000 top subdomains
- **Tools**: assetfinder, crt.sh, findomain, subfinder, sublist3r, puredns
- **Use case**: Quick scope discovery, reconnaissance

### Deep Mode (`--deep`)
Best for comprehensive enumeration:
- **Duration**: 15-45 minutes
- **Wordlist**: 110,000 comprehensive list
- **Tools**: All fast mode + Amass + FFUF bruteforcing
- **Use case**: Complete asset discovery, thorough testing

## 🏗️ Architecture

Autohunt's modular design makes it easy to extend with new capabilities:

```
autohunt/
├── lib/
│   └── common.sh                # Shared utility functions
├── subtools/                    # Security tool modules
│   ├── subdenum/                # Subdomain enumeration
│   │   ├── subdenum.sh
│   │   ├── resolver.txt
│   │   └── wordlists/
│   └── (future tools...)
├── config/
│   └── autohunt.conf.template   # Configuration template
├── setup.sh                     # Automated installer
├── autohunt.sh                  # Main CLI entry point
├── autohunt.bash_completion     # Shell completion
└── README.md
```

### Adding a New Subtool

1. **Create the subtool directory:**
```bash
mkdir -p subtools/mytool
```

2. **Create the main script** (`subtools/mytool/mytool.sh`):
```bash
#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")
source "${ROOT_DIR}/lib/common.sh"

main() {
    msg header "My Tool"
    # Your implementation here
}

main "$@"
```

3. **Register dependencies** in `setup.sh`

4. **Use immediately:**
```bash
autohunt mytool [options]
```

## ⚡ Tips for Bug Hunters

1. **Run fast mode frequently** – Use for rapid reconnaissance and scope mapping
2. **Schedule deep scans** – Run overnight for comprehensive asset discovery
3. **Filter before analysis** – Use `alive.txt` to focus on responsive hosts
4. **Review screenshots first** – Quickly identify interesting targets in `screenshots/`
5. **Export to CSV** – Import `subdomains.csv` into your tools for further analysis
6. **Respect rate limits** – Add delays between scans to avoid blocking

## 🔒 Security Considerations

- **Network Impact**: Deep scans generate significant traffic. Use responsibly.
- **Rate Limiting**: Respect target rate limits to avoid detection/blocking
- **Authorization**: Only test targets you have explicit written permission for
- **Data Security**: Results contain sensitive info—store in secure location
- **Scope Awareness**: Stick to your authorized scope during assessments

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Submit a pull request

## 📚 Documentation

- [Getting Started](docs/00_START_HERE.md)
- [Installation Guide](docs/INSTALLATION.md)
- [Architecture Details](docs/ARCHITECTURE.md)
- [Full Reference](docs/REFERENCE.md)
- [Changelog](docs/CHANGES.md)

## 📄 License

MIT License – See [LICENSE](LICENSE) for details

## 🔗 Resources

- [Assetfinder](https://github.com/tomnomnom/assetfinder)
- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [HTTPX](https://github.com/projectdiscovery/httpx)
- [Amass](https://github.com/owasp-amass/amass)
- [FFUF](https://github.com/ffuf/ffuf)
- [Gowitness](https://github.com/sensepost/gowitness)

## 🙋 Support

- **Issues**: Report bugs via [GitHub Issues](https://github.com/ncodevsec/autohunt/issues)
- **Discussions**: Check existing issues first
- **Suggestions**: Open an enhancement issue

---

**Made with ❤️ for security researchers and bug bounty hunters**

**Version**: 1.0.0 | **Last Updated**: May 2026
- Use `deep` mode for comprehensive enumeration before a full engagement.
- Combine output with other tools (e.g. nuclei, dirsearch) for deeper testing.
- Review the script output and logs for any missing dependencies or errors.
- Customize the wordlist and scan logic as needed for your workflow.
