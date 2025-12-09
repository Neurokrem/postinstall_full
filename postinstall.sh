#!/bin/bash

# ======================================================
#  APT LOCK FIX  — run BEFORE set -e
# ======================================================
echo "[fix] Forcing unlock of APT..."

# Kill interfering processes (safe; won't stop script)
sudo killall packagekit 2>/dev/null || true
sudo killall fwupd 2>/dev/null || true
sudo killall pop-shop 2>/dev/null || true
sudo killall apt.systemd.daily 2>/dev/null || true
sudo killall unattended-upgrade 2>/dev/null || true

# Stop services that may restart automatically
sudo systemctl stop packagekit.service 2>/dev/null || true
sudo systemctl stop fwupd.service 2>/dev/null || true
sudo systemctl stop pop-shop.service 2>/dev/null || true
sudo systemctl stop unattended-upgrades.service 2>/dev/null || true

# Remove APT lock files
sudo rm -f /var/lib/apt/lists/lock || true
sudo rm -f /var/cache/apt/archives/lock || true
sudo rm -f /var/lib/dpkg/lock* || true
sudo rm -f /var/lib/dpkg/lock-frontend || true

# Repair dpkg state
sudo dpkg --configure -a || true

echo "[fix] APT fully unlocked."
echo

# ======================================================
# SAFETY OPTIONS (NOW WE TURN THEM ON)
# ======================================================
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "====================================================="
echo "     POSTINSTALL STARTED"
echo "====================================================="

# ======================================================
# 0) Install prerequisites
# ======================================================
echo "[0] Installing base prerequisites..."
sudo apt update
sudo apt install -y software-properties-common ca-certificates curl wget gnupg lsb-release

# ======================================================
# 1) APT INSTALL PACKAGES
# ======================================================
echo "[1] Installing APT packages..."

if [[ -f "$REPO_DIR/apt/install.sh" ]]; then
    echo "Installing packages from apt/install.sh"
    xargs -a "$REPO_DIR/apt/install.sh" sudo apt install -y
else
    echo "No apt/install.sh found. Skipping."
fi

# ======================================================
# 2) FLATPAK
# ======================================================
echo "[2] Installing Flatpak packages..."

if [[ -f "$REPO_DIR/flatpak/install.sh" ]]; then
    while read -r pkg; do
        [[ -z "$pkg" ]] && continue
        flatpak install -y "$pkg" || true
    done < "$REPO_DIR/flatpak/install.sh"
else
    echo "No flatpak/packages.txt found. Skipping."
fi

# ======================================================
# 3) LANGUAGES (DISABLED)
# ======================================================
echo "[3] Skipping language installers (Go, rbenv, Anaconda)."

# Uncomment if you ever want to re-enable:
# bash "$REPO_DIR/languages/install_go.sh"
# bash "$REPO_DIR/languages/install_rbenv.sh"
# bash "$REPO_DIR/languages/install_conda.sh"

# ======================================================
# 4) DOTFILES
# ======================================================
echo "[4] Copying dotfiles..."

if [[ -d "$REPO_DIR/dotfiles" ]]; then
    cp -r "$REPO_DIR/dotfiles/." "$HOME/"
else
    echo "No dotfiles directory found. Skipping."
fi

# ======================================================
# 5) COSMIC CONFIG
# ======================================================
echo "[5] Applying COSMIC configuration..."

if [[ -d "$REPO_DIR/cosmic" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "$REPO_DIR/cosmic/"* "$HOME/.config/"
else
    echo "No cosmic directory found. Skipping."
fi

# ======================================================
# 6) WALLPAPER (CUSTOM DIRECTORY)
# ======================================================
echo "[6] Setting wallpaper..."

# Ensure destination exists
mkdir -p "$HOME/Slike/Wallpaper"

# Copy wallpaper from repo (edit filename if needed)
if [[ -f "$REPO_DIR/wallpapers/jutro 4K.jpg" ]]; then
    cp "$REPO_DIR/wallpapers/jutro 4K.jpg" "$HOME/Slike/Wallpaper/jutro 4K.jpg"

    # Set wallpaper through GNOME/COSMIC schemas
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Slike/Wallpaper/jutro 4K.jpg"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/Slike/Wallpaper/jutro 4K.jpg"
else
    echo "No wallpapers/default.jpg found. Skipping wallpaper setup."
fi

# ======================================================
# 10) SHELL CONFIG
# ======================================================
echo "[10] Applying ZSH/P10K configuration..."

if [[ -f "$REPO_DIR/dotfiles/.zshrc" ]]; then
    cp "$REPO_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
fi

# ======================================================
# 11) FINAL CLEANUP
# ======================================================
echo "[11] Final cleanup..."
sudo apt autoremove -y || true
sudo apt autoclean -y || true
flatpak uninstall --unused -y || true

echo "====================================================="
echo "     POSTINSTALL COMPLETE"
echo "====================================================="
echo "Please restart your system or run:  source ~/.zshrc"
