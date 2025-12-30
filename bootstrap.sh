#!/bin/bash
set -euo pipefail

echo "====================================================="
echo "   POSTINSTALL BOOTSTRAP START"
echo "====================================================="

# 1) Provjera da je git instaliran
if ! command -v git >/dev/null 2>&1; then
    echo "[+] Installing git..."
    # Osnovni korak (može zahtijevati sudo)
    sudo apt update
    sudo apt install -y git
fi

# 2) Kreiranje privremene mape
TMPDIR=$(mktemp -d)

# Varijabla za Vaš repozitorij
REPO_URL="https://github.com/Neurokrem/postinstall_full.git"

echo "[+] Cloning repository $REPO_URL into: $TMPDIR"
git clone "$REPO_URL" "$TMPDIR"

# 3) Provjera da je kloniranje uspjelo
if [ ! -f "$TMPDIR/postinstall.sh" ]; then
    echo "[ERROR] postinstall.sh not found in cloned repo! Aborting."
    exit 1
fi

cd "$TMPDIR"

# *****************************************************
# VAŽNA PREPRAVKA: Postavljanje dozvola za SVE skripte
# *****************************************************
echo "[+] Setting execute permissions for all .sh scripts..."
find . -name "*.sh" -exec chmod +x {} \;
# *****************************************************

echo "-----------------------------------------------------"
echo "  Running postinstall.sh..."
echo "-----------------------------------------------------"

# Sada smo sigurni da postinstall.sh i sve pod-skripte imaju dozvolu za izvođenje
./postinstall.sh

echo "-----------------------------------------------------"
echo "  Postinstall completed."
echo "-----------------------------------------------------"

echo "Cleaning up temporary directory..."
# Oprezno uklanjanje privremenog foldera
rm -rf "$TMPDIR"

echo "====================================================="
echo "   BOOTSTRAP DONE — restart recommended"
echo "====================================================="