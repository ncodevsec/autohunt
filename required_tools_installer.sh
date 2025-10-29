# Go lang
latest=$(curl -s https://go.dev/VERSION?m=text | head -n 1 | tr -d '\r')
sudo rm -rf /usr/local/go
wget "https://go.dev/dl/${latest}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
grep -qxF 'export PATH=$PATH:/usr/local/go/bin' ~/.bashrc || echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
grep -qxF 'export GOPATH=$HOME/go' ~/.bashrc || echo 'export GOPATH=$HOME/go' >> ~/.bashrc
grep -qxF 'export PATH=$PATH:$GOPATH/bin' ~/.bashrc || echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

# Assetfinder
go install github.com/tomnomnom/assetfinder@latest

# Subfinder
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# Amass
go install github.com/owasp-amass/amass/v4/cmd/amass@latest

# HTTPX
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# Gowitness
go install github.com/sensepost/gowitness@latest

# Puredns
git clone https://github.com/blechschmidt/massdns.git
cd massdns
make
sudo make install
go install github.com/d3mondev/puredns/v2@latest
cd ../

# Findomain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
git clone https://github.com/findomain/findomain.git
cd findomain
cargo build --release
sudo cp target/release/findomain /usr/bin/
cd ../

# Sublist3r
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
sudo pipx install sublist3r
cd ../

# CSVkit
sudo pipx install csvkit
