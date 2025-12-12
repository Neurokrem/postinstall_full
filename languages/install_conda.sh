#!/bin/bash
set -euo pipefail

ANACONDA_SH="$HOME/Anaconda3-latest-Linux-x86_64.sh"
CONDA_DIR="$HOME/anaconda3"

echo "Downloading Anaconda installer..."
# Koristimo -O da preuzimanje bude vidljivo (ne -q)
wget https://repo.anaconda.com/archive/Anaconda3-latest-Linux-x86_64.sh -O "${ANACONDA_SH}"

echo "Installing Anaconda (non-interactive) to $CONDA_DIR ..."
# -b (batch), -p (prefix)
bash "${ANACONDA_SH}" -b -p "$CONDA_DIR"
rm -f "${ANACONDA_SH}"

# Provjera je li instalacija uspjela
if [ ! -f "$CONDA_DIR/bin/conda" ]; then
    echo "ERROR: Conda installation failed or was interrupted. Check logs above." >&2
    exit 1
fi

# Privremeno dodajemo Conda bin direktorij u PATH skripte
# Ovo je ključno kako bi Conda init mogao raditi u sljedećem koraku
export PATH="$CONDA_DIR/bin:$PATH"

# Trajno dodavanje PATH-a u ~/.zshrc
grep -qxF 'export PATH="$HOME/anaconda3/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.zshrc

# Inicijalizacija conda za zsh
echo "Initializing Conda for Zsh..."
# Naredba će raditi jer je Conda sada u PATH unutar skripte
"$CONDA_DIR/bin/conda" init zsh

echo "Anaconda installed. Restart shell or run: source ~/.zshrc"