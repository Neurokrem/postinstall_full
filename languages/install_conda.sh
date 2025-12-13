#!/bin/bash
set -euo pipefail

ANACONDA_SH="$HOME/Anaconda3-latest-Linux-x86_64.sh"
CONDA_DIR="$HOME/anaconda3"

echo "Downloading Anaconda installer..."
# UKLONJENO -q (quiet) da bismo vidjeli eventualnu grešku 404/server error
wget https://repo.anaconda.com/archive/Anaconda3-latest-Linux-x86_64.sh -O "${ANACONDA_SH}"

echo "Installing Anaconda (non-interactive) to $CONDA_DIR ..."

# Provjera postoji li već instalacija (da izbjegnemo grešku instalera)
if [ -d "$CONDA_DIR" ]; then
    echo "WARNING: Conda directory already exists. Removing old installation..."
    rm -rf "$CONDA_DIR"
fi

# Pokrećemo instalaciju.
# -b (batch mode), -p (prefix/install path)
bash "${ANACONDA_SH}" -b -p "$CONDA_DIR"
rm -f "${ANACONDA_SH}"

# ROBUSTNA PROVJERA: Ako instalacija nije stvorila izvršnu datoteku, prekini skriptu.
if [ ! -f "$CONDA_DIR/bin/conda" ]; then
    echo "ERROR: Conda installation failed! The 'conda' executable was not found." >&2
    exit 1
fi

# Trajno dodavanje PATH-a u ~/.zshrc (ako već nije dodano)
grep -qxF 'export PATH="$HOME/anaconda3/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.zshrc

# Inicijalizacija conda za zsh
echo "Initializing Conda for Zsh..."
# Koristimo punu putanju; || true osigurava da skripta ne stane ako init prijavi warning.
"$CONDA_DIR/bin/conda" init zsh || true

echo "Anaconda installed. Restart shell or run: source ~/.zshrc"