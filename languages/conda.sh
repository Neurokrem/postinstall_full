#!/usr/bin/env bash

set -e

echo "[Conda] Installing latest Anaconda3 (full)..."

# 1) Odredi Downloads / Preuzimanja
DOWNLOAD_DIR="$HOME/Downloads"
if [ -d "$HOME/Preuzimanja" ]; then
    DOWNLOAD_DIR="$HOME/Preuzimanja"
fi

echo " → Using download directory: $DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 2) Dohvati ime najnovijeg Linux x86_64 instalera
echo " → Fetching latest Anaconda installer name..."

ANACONDA_SH=$(curl -s https://repo.anaconda.com/archive/ \
    | grep -oE 'Anaconda3-[0-9.]+-[0-9]+-Linux-x86_64\.sh' \
    | sort -V \
    | tail -n 1)

if [ -z "$ANACONDA_SH" ]; then
    echo "ERROR: Could not determine latest Anaconda installer."
    exit 1
fi

echo " → Latest installer: $ANACONDA_SH"

# 3) Preuzmi installer ako već ne postoji
if [ ! -f "$ANACONDA_SH" ]; then
    echo " → Downloading Anaconda..."
    wget -q "https://repo.anaconda.com/archive/$ANACONDA_SH"
else
    echo " → Installer already present, skipping download."
fi

# 4) Pokreni instalaciju (NAMJERNO interaktivno)
echo
echo "=== Anaconda installer will now start ==="
echo "Follow the prompts:"
echo " - Accept license"
echo " - Default install location is recommended"
echo " - Allow conda init when asked"
echo

bash "$DOWNLOAD_DIR/$ANACONDA_SH"

echo
echo "✔ Anaconda installer finished."
echo "⚠ Log out and log b
