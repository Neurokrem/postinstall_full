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

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "====================================================="
echo "     POSTINSTALL STARTED"
echo "====================================================="

# -------------------------------------------------------
# 0) Ensure dependencies needed for PPAs
# -------------------------------------------------------
echo "[0] Installing base prerequisites..."
sudo apt update
sudo apt install -y software-properties-common ca-certificates curl wget gnupg lsb-release

# -------------------------------------------------------
# 1) CLEAN DEFAULT JUNK (free space before heavy installs)
# -------------------------------------------------------
echo "[1] Removing unwanted preinstalled applications..."

sudo apt purge -y \
  libreoffice-base* \
  libreoffice-calc* \
  libreoffice-core* \
  libreoffice-draw* \
  libreoffice-gnome* \
  libreoffice-impress* \
  libreoffice-math* \
  libreoffice-writer* \
  libreoffice-common \
  libreoffice-style* \
  geary \
  thunderbird \
  gnome-mahjongg \
  gnome-mines \
  gnome-sudoku || true

sudo apt autoremove -y || true
sudo apt autoclean -y || true

echo "[1] Cleanup completed."

# -------------------------------------------------------
# 2) FULL SYSTEM UPDATE BEFORE INSTALLATION
# -------------------------------------------------------
echo "[2] Updating system..."
sudo apt update
sudo apt upgrade -y

# -------------------------------------------------------
# 3) ADD CUSTOM REPOSITORIES (PPAs)
# -------------------------------------------------------
echo "[3] Adding custom repositories..."

## Kisak Mesa
if ! grep -Rq "kisak/kisak-mesa" /etc/apt/; then
    echo " → Kisak Mesa"
    sudo add-apt-repository -y ppa:kisak/kisak-mesa
fi

## MEGAsync instalacija
echo " → MEGAsync (.deb install)"

(
    TMP_DEB="/tmp/megasync.deb"
    wget -O "$TMP_DEB" "https://mega.nz/linux/repo/xUbuntu_24.04/amd64/megasync-xUbuntu_24.04_amd64.deb" || true
    sudo apt install -y "$TMP_DEB" || true
    sudo apt --fix-broken install -y || true
    sudo apt install -y "$TMP_DEB" || true
    rm -f "$TMP_DEB"
)

## QFinder Pro
echo " → QFinder Pro (.deb install)"

(
    TMP_DEB="/tmp/qfinder.deb"
    wget -O "$TMP_DEB" "https://download.qnap.com/QfinderPro/7.13.0.1014/QNAPQfinderProUbuntux64-7.13.0.1014.deb" || true
    sudo apt install -y "$TMP_DEB" || true
    sudo apt --fix-broken install -y || true
    sudo apt install -y "$TMP_DEB" || true
    rm -f "$TMP_DEB"
)

## Master PDF Editor (Code Industry)
echo " → Master PDF Editor (.deb install only — repo disabled)"
(
    TMP_DEB="/tmp/masterpdf.deb"
    wget -O "$TMP_DEB" "https://code-industry.net/public/master-pdf-editor-5.9.60-qt5.x86_64.deb" || true
    sudo apt install -y "$TMP_DEB" || true
    sudo apt --fix-broken install -y || true
    sudo apt install -y "$TMP_DEB" || true
    rm -f "$TMP_DEB"
)

## VScode
echo " → Adding VSCode repo (non-interactive)"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor \
    | sudo tee /usr/share/keyrings/ms_vscode.gpg >/dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ms_vscode.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

echo "[3] Repositories added."

# -------------------------------------------------------
# 4) REFRESH APT AFTER REPOS
# -------------------------------------------------------
echo "[4] Refreshing APT after adding repositories..."
sudo apt update

# -------------------------------------------------------
# 5) RUN APT INSTALLER SCRIPT
# -------------------------------------------------------
echo "[5] Installing APT packages..."
bash "$REPO_DIR/apt/install.sh"

# -------------------------------------------------------
# 6) RUN FLATPAK INSTALLER SCRIPT
# -------------------------------------------------------
echo "[6] Installing Flatpak packages..."

# guarantee flathub
if ! flatpak remotes | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

flatpak uninstall --unused -y || true
bash "$REPO_DIR/flatpak/install.sh"

# -------------------------------------------------------
# 7) GO, RBENV, ANACONDA INSTALL
# -------------------------------------------------------
#echo "[7] Installing Go..."
#bash "$REPO_DIR/languages/install_go.sh"

#echo "[7] Installing rbenv..."
#bash "$REPO_DIR/languages/install_rbenv.sh"

#echo "[7] Installing Anaconda..."
#bash "$REPO_DIR/languages/install_conda.sh"


# -------------------------------------------------------
# 8) RESTORE COSMIC CONFIG
# -------------------------------------------------------
if [ -d "$REPO_DIR/cosmic" ]; then
    echo "[9] Restoring COSMIC settings..."
    mkdir -p "$HOME/.config/cosmic"
    cp -r "$REPO_DIR/cosmic/." "$HOME/.config/cosmic/"
fi

# -------------------------------------------------------
# 9) WALLPAPER
# -------------------------------------------------------
WALL="$REPO_DIR/wallpapers/jutro 4K.jpg"
TARGET="$HOME/Slike/Wallpaper/jutro 4K.jpg"

if [ -f "$WALL" ]; then
    echo "[10] Installing wallpaper..."
    mkdir -p "$HOME/Slike/Wallpaper"
    cp "$WALL" "$TARGET"

    # GNOME / COSMIC wallpaper set
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Slike/Wallpaper/jutro 4K.jpg"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/Slike/Wallpaper/jutro 4K.jpg"
fi

# -------------------------------------------------------
# 10) RESTORE DOTFILES
# -------------------------------------------------------
if [ -d "$REPO_DIR/dotfiles" ]; then
    echo "[8] Restoring dotfiles..."
    cp -r "$REPO_DIR/dotfiles/." "$HOME/"
fi

# Dodavanje Kitty konfiguracije
echo "[kitty] Installing Kitty configuration..."
mkdir -p "$HOME/.config/kitty"
cp -r "$REPO_DIR/kitty/." "$HOME/.config/kitty/"

# -------------------------------------------------------
# 11) FINAL CLEANUP
# -------------------------------------------------------
echo "[11] Final cleanup..."
sudo apt autoremove -y || true
sudo apt autoclean -y || true
flatpak uninstall --unused -y || true

## Postavljanje ZSH
echo "[zsh] Fixing ZSH shell setup for COSMIC..."

# ensure zsh installed
sudo apt install -y zsh

# hard-force login shell in /etc/passwd (COSMIC bugfix)
sudo sed -i "s#^\($USER:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\).*#\1/usr/bin/zsh#" /etc/passwd
chsh -s /usr/bin/zsh "$USER" || true

echo "[zsh4humans] Installing using a real ZSH session..."

# run installer AS USER inside ZSH (NOT bash!)
sudo -u "$USER" zsh -c 
    if command -v curl >/dev/null; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
    else
        sh -c "$(wget -O- https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
    fi

echo "[p10k] Applying custom theme..."
cp "$REPO_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"

echo "====================================================="
echo "     POSTINSTALL COMPLETE"
echo "====================================================="
echo "Please restart your system or run:  source ~/.zshrc"
