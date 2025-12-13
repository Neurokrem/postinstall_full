#!/bin/bash
set -euo pipefail

# Definira putanju do glavnog direktorija repozitorija
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing Zsh and prerequisites..."

# 1. Instalacija Zsh
sudo apt install -y zsh

# 2. Postavljanje Zsh kao zadane ljuske
echo "Changing default shell to Zsh for user $USER..."
# Korištenje 'sudo chsh -s ... $USER' osigurava neinteraktivnu promjenu ljuske za aktivnog korisnika.
sudo chsh -s "$(which zsh)" "$USER"

# 3. Instalacija zsh4humans
if [ ! -d "$HOME/.zsh4humans" ]; then
    echo "Installing zsh4humans..."
    git clone https://github.com/romkatv/zsh4humans.git "$HOME/.zsh4humans"
else
    echo "zsh4humans directory already exists. Pulling latest changes..."
    (cd "$HOME/.zsh4humans" && git pull)
fi

# 4. Postavljanje .zshrc (KRITIČNA KOREKCIJA: zsh4humans.zsh -> init.zsh)
echo "Creating/Updating ~/.zshrc for zsh4humans..."
cat > "$HOME/.zshrc" << 'EOF'
# Zsh4humans initialization
source ~/.zsh4humans/init.zsh 
EOF

# 5. Konfiguracija Powerlevel10k (p10k)
if [ -d "$REPO_DIR/p10k" ]; then
    echo "Restoring p10k configurations (.p10k.zsh and .p10k-8color.zsh)..."
    
    # Kopiranje glavne konfiguracije
    cp "$REPO_DIR/p10k/.p10k.zsh" "$HOME/"
    
    # Kopiranje 8-color konfiguracije za kompatibilnost
    if [ -f "$REPO_DIR/p10k/.p10k-8color.zsh" ]; then
        cp "$REPO_DIR/p10k/.p10k-8color.zsh" "$HOME/"
    fi

else
    echo "WARNING: p10k configuration directory not found at $REPO_DIR/p10k. p10k will use default settings."
fi

echo "Zsh and zsh4humans installation script finished. Please restart your session."