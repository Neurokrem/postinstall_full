#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "Running apt installer..."
bash "$REPO_DIR/apt/install.sh"

echo "Running flatpak installer..."
bash "$REPO_DIR/flatpak/install.sh"

echo "Installing Go..."
bash "$REPO_DIR/languages/install_go.sh"

echo "Installing rbenv..."
bash "$REPO_DIR/languages/install_rbenv.sh"

echo "Installing Anaconda..."
bash "$REPO_DIR/languages/install_conda.sh"

# Copy dotfiles if present
if [ -d "$REPO_DIR/dotfiles" ] && [ "$(ls -A "$REPO_DIR/dotfiles")" ]; then
  echo "Copying dotfiles to $HOME..."
  cp -r "$REPO_DIR/dotfiles/." "$HOME/"
fi

# Restore COSMIC config if present
if [ -d "$REPO_DIR/cosmic" ] && [ "$(ls -A "$REPO_DIR/cosmic")" ]; then
  echo "Restoring COSMIC configuration..."
  mkdir -p "$HOME/.config/cosmic"
  cp -r "$REPO_DIR/cosmic/." "$HOME/.config/cosmic/"
fi

# Wallpaper installer
WALL="$REPO_DIR/wallpapers/jutro 4K.jpg"
TARGET="$HOME/.local/share/backgrounds/jutro 4K.jpg"

if [ -f "$WALL" ]; then
    echo "Installing wallpaper..."
    mkdir -p "$HOME/.local/share/backgrounds"
    cp "$WALL" "$TARGET"

    # Set wallpaper – COSMIC uses GNOME backend dok COSMIC Settings ne dođu
    gsettings set org.gnome.desktop.background picture-uri "file://$TARGET" || true
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$TARGET" || true
fi

echo "Postinstall complete. Please restart or 'source ~/.zshrc' to finalize shell changes."
