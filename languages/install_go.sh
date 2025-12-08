#!/bin/bash
set -euo pipefail

GO_VERSION="1.22.5"
TMP_TAR="/tmp/go${GO_VERSION}.linux-amd64.tar.gz"

echo "Downloading Go ${GO_VERSION}..."
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O "${TMP_TAR}"

echo "Installing Go to /usr/local (requires sudo)..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "${TMP_TAR}"
rm -f "${TMP_TAR}"

# user environment (append if missing)
grep -qxF 'export PATH="/usr/local/go/bin:$PATH"' ~/.zshrc || echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.zshrc
grep -qxF 'export GOPATH="$HOME/go"' ~/.zshrc || echo 'export GOPATH="$HOME/go"' >> ~/.zshrc
grep -qxF 'export PATH="$GOPATH/bin:$PATH"' ~/.zshrc || echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.zshrc

echo "Go installed. Restart shell or run: source ~/.zshrc"
