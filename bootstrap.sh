#!/bin/bash
set -euo pipefail

echo "====================================================="
echo "   POSTINSTALL BOOTSTRAP START"
echo "====================================================="

# 1) Provjera da je git instaliran
if ! command -v git >/dev/null 2>&1; then
    echo "[+] Installing git..."
    sudo apt update
    sudo apt install -y git
fi

# 2) Kreiranje privremene mape
TMPDIR=$(mktemp -d)

echo "[+] Cloning repository into: $TMPDIR"
git clone https://github.com/Neurokrem/postinstall_full.git "$TMPDIR"

# 3) Provjera da je kloniranje uspjelo
if [ ! -f "$TMPDIR/postinstall.sh" ]; then
    echo "[ERROR] postinstall.sh not found in cloned repo!"
    exit 1
fi

cd "$TMPDIR"
chmod +x postinstall.sh

echo "-----------------------------------------------------"
echo "  Running postinstall.sh..."
echo "-----------------------------------------------------"

./postinstall.sh

echo "-----------------------------------------------------"
echo "  Postinstall completed."
echo "-----------------------------------------------------"

echo "Cleaning up temporary directory..."
rm -rf "$TMPDIR"

echo "====================================================="
echo "   BOOTSTRAP DONE — restart recommended"
echo "====================================================="

