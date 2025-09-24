
# subdenum – Automated Subdomain Enumeration & Recon Toolkit

A fast and extensible Bash script for **subdomain enumeration** and **live host detection**.
`subdenum` combines multiple industry-standard tools into a single workflow, automatically aggregating results, filtering duplicates, and optionally taking screenshots with Aquatone. The script now supports improved output handling, error checking, and flexible scan modes.



## ✨ Features

- **Multi-source subdomain discovery**: `assetfinder`, `crt.sh`, `findomain`, `subfinder`, `sublist3r`, `puredns`, `amass` (deep mode), `ffuf` (deep mode).
- **Bruteforce support** with configurable wordlists (default: top 20,000 subdomains).
- **Live host detection** using `httpx` (CSV output).
- **Screenshot & site mapping** via Aquatone (function included, call is commented by default).
- **Fast and Deep scan modes**: Deep mode adds Amass and FFUF for more comprehensive results.
- **Automatic tool and wordlist checks**: Script verifies dependencies and wordlist presence before running.
- **Structured output** in `$HOME/bug_hunting_data/<target>/subdomain`.



## 🛠️ Requirements

Install the following tools before running:

- [assetfinder](https://github.com/tomnomnom/assetfinder)
- [jq](https://stedolan.github.io/jq/)
- [curl](https://curl.se/)
- [subfinder](https://github.com/projectdiscovery/subfinder)
- [sublist3r](https://github.com/aboul3la/Sublist3r)
- [findomain](https://github.com/findomain/findomain)
- [puredns](https://github.com/d3mondev/puredns)
- [massdns](https://github.com/blechschmidt/massdns)
- [ffuf](https://github.com/ffuf/ffuf) *(Deep mode)*
- [amass](https://github.com/owasp-amass/amass) *(Deep mode)*
- [httpx](https://github.com/projectdiscovery/httpx)
- [Aquatone](https://github.com/michenriksen/aquatone) *(optional for screenshots)*

Also, ensure you have a valid resolver list at `resolver.txt` inside the script directory.
The default wordlist is `/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt`.


## 📦 Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/ncodevsec/autohunt.git && cd autohunt && chmod +x subdenum.sh
# Clone repo
cd autohunt

# Make setup script executable
chmod +x setup.sh

# Install alias
./setup.sh -i

# Run the tool
subdenum <domain>

# Uninstall alias
./setup.sh uninstall

# Show setup help
./setup.sh -h

```

One line installation command
```bash
git clone https://github.com/ncodevsec/autohunt.git && cd autohunt && chmod +x setup.sh && ./setup.sh -i && source ~/.bashrc
```

Update the wordlist path in the script if needed:
```bash
# Edit the WORDLIST variable in subdenum.sh if you want a different wordlist
WORDLIST="/usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top500.txt"
```


## 🚀 Usage

```bash
subdenum <target-domain> <option>
```
```bash
Options:
   blank        Scan in Normal Mode (Default)
   --deep       Scan in Deep Mode

Example:
  subdenum example.com          # To run in normal mode
  subdemun example.com --deep   # To run in deep mode
```


- `<target-domain>`: Domain to enumerate (e.g. `example.com`)
- `<mode>`: `fast` (default) or `deep`
    - `deep` mode runs additional tools like Amass and FFUF for brute forcing and extended enumeration.

Examples:

```bash
# Fast Mode (default)
subdenum example.com

# Deep Mode (more comprehensive)
subdenum example.com deep
```


## 📂 Output Structure

Results are stored under:

```
$HOME/bug_hunting_data/<target-domain>/subdomain/
```

Files include:

- `amass.txt` – Amass results (deep mode)
- `assetfinder.txt` – Assetfinder results
- `crt.txt` – crt.sh extracted subdomains
- `findomain.txt` – Findomain results
- `puredns.txt` – PureDNS brute force results
- `subfinder.txt` – Subfinder results
- `sublist3r.txt` – Sublist3r results
- `sort.txt` – All merged & unique subdomains
- `all.txt` – Cleaned, protocol-stripped subdomains (input for httpx)
- `httpx.csv` – Live hosts (CSV output from httpx)
- `aquatone/` – Screenshots and HTML report (if Aquatone run)


## 📝 Notes

- Ensure your wordlist and `resolver.txt` are correctly configured.
- Aquatone execution is defined but commented out — uncomment the `aquatone` function call in the script to enable screenshots.
- The script now merges and cleans all subdomain results, strips protocols, and outputs to `all.txt` before live host checking.
- Live host filtering is performed with `httpx` and results are saved as CSV in `httpx.csv`.
- Output directory is now `$HOME/bug_hunting_data/<target>/subdomain`.


## 💡 Tips for Bug Hunters

- Run `fast` mode frequently for quick recon.
- Use `deep` mode for comprehensive enumeration before a full engagement.
- Combine output with other tools (e.g. nuclei, dirsearch) for deeper testing.
- Review the script output and logs for any missing dependencies or errors.
- Customize the wordlist and scan logic as needed for your workflow.
