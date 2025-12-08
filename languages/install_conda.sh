#!/bin/bash
set -euo pipefail

ANACONDA_SH="$HOME/Anaconda3-latest-Linux-x86_64.sh"

echo "Downloading Anaconda installer..."
wget -q https://repo.anaconda.com/archive/Anaconda3-latest-Linux-x86_64.sh -O "${ANACONDA_SH}"

echo "Installing Anaconda (non-interactive) to $HOME/anaconda3 ..."
bash "${ANACONDA_SH}" -b -p "$HOME/anaconda3"
rm -f "${ANACONDA_SH}"

# Add to PATH for zsh if not present
grep -qxF 'export PATH="$HOME/anaconda3/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.zshrc

# Initialize conda for zsh (best-effort, non-fatal)
"$HOME/anaconda3/bin/conda" init zsh || true

echo "Anaconda installed. Restart shell or run: source ~/.zshrc"
