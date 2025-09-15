# subdenum – Automated Subdomain Enumeration & Recon Toolkit

A fast and extensible Bash script for **subdomain enumeration** and **live host detection**.
`subdenum` combines multiple industry-standard tools into a single workflow, automatically aggregating results, filtering duplicates, and optionally taking screenshots with Aquatone.



## ✨ Features

- **Multi-source subdomain discovery**: `assetfinder`, `crt.sh`, `findomain`, `subfinder`, `puredns`, `amass` (deep mode).
- **Bruteforce support** with configurable wordlists.
- **Live host detection** using `httpx`.
- **Screenshot & site mapping** via Aquatone.
- **Structured output** in `$HOME/data/<target>/subdomain`.



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



## 📦 Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/ncodevsec/autohunt.git && chmod +x autohunt/subdenum.sh
```

Update the wordlist path in the script if needed:
```
WORDLIST="/usr/share/seclists/Discovery/DNS/deepmagic.com-prefixes-top500.txt"
```



## 🚀 Usage

```bash
./subdenum.sh <target-domain> <mode>

```

- `<target-domain>`: Domain to enumerate (e.g. `example.com`)
- `<mode>`: `fast` (default) or `deep`
    - `deep` mode runs additional tools like Amass and FFUF, brute forcing.

Examples:

```bash
# Normal Mode
./subdenum.sh example.com

# Deep Mode 
./subdenum.sh example.com deep
```



## 📂 Output Structure

Results are stored under:

```
$HOME/data/<target-domain>/subdomain/
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
- `httpx.txt` – Live hosts (status 20x)
- `aquatone/` – Screenshots and HTML report (if Aquatone run)



## 📝 Notes

- Ensure your wordlist and `resolver.txt` are correctly configured.
- Aquatone execution is defined but commented out — uncomment `aquatone` function call to enable screenshots.
- The script filters only `20x` HTTP responses by default; adjust the `grep '\[20'` line for other status codes.



## 📜 License

This project is licensed under the MIT License – see LICENSE for details.



## 💡 Tips for Bug Hunters

- Run `fast` mode frequently for quick recon.
- Use `deep` mode for comprehensive enumeration before a full engagement.
- Combine output with other tools (e.g. nuclei, dirsearch) for deeper testing.
