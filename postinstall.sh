#!/bin/bash

# ======================================================
#  RIGOROUS ERROR HANDLING & ENVIRONMENT SETUP
# ======================================================
# set -e: Izlazak ako bilo koja naredba ne uspije
# set -u: Izlazak ako se koristi nedefinirana varijabla
# set -o pipefail: Neuspjeh ako ijedna naredba u pipe-u ne uspije
set -euo pipefail

# Definiranje direktorija skripte
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "====================================================="
echo "     POSTINSTALL STARTED"
echo "====================================================="


# ======================================================
#  0) APT LOCK FIX
# ======================================================
# Ovaj blok je namjerno postavljen prije set -e/u,
# ali ga sada omotavamo u podshell da bi set -e bio na vrhu
(
    set +euo pipefail # Privremeno isključivanje stroge provjere za ovaj neuredni popravak
    echo "[fix] Forcing unlock of APT..."

    sudo killall packagekit 2>/dev/null || true
    sudo killall fwupd 2>/dev/null || true
    sudo killall pop-shop 2>/dev/null || true
    sudo killall apt.systemd.daily 2>/dev/null || true
    sudo killall unattended-upgrade 2>/dev/null || true

    sudo systemctl stop packagekit.service 2>/dev/null || true
    sudo systemctl stop fwupd.service 2>/dev/null || true
    sudo systemctl stop pop-shop.service 2>/dev/null || true
    sudo systemctl stop unattended-upgrades.service 2>/dev/null || true

    sudo rm -f /var/lib/apt/lists/lock || true
    sudo rm -f /var/cache/apt/archives/lock || true
    sudo rm -f /var/lib/dpkg/lock* || true
    sudo rm -f /var/lib/dpkg/lock-frontend || true

    sudo dpkg --configure -a || true

    echo "[fix] APT fully unlocked."
    echo
)


# -------------------------------------------------------
# 1) Ensure dependencies needed for PPAs
# -------------------------------------------------------
echo "[1] Installing base prerequisites..."
sudo apt update
# Dodan 'git' i 'build-essential'
sudo apt install -y software-properties-common ca-certificates curl wget gnupg lsb-release git build-essential

# -------------------------------------------------------
# 2) CLEAN DEFAULT JUNK (free space before heavy installs)
# -------------------------------------------------------
echo "[2] Removing unwanted preinstalled applications..."

sudo apt purge -y \
  libreoffice-base* libreoffice-calc* libreoffice-core* libreoffice-draw* \
  libreoffice-gnome* libreoffice-impress* libreoffice-math* libreoffice-writer* \
  libreoffice-common libreoffice-style* geary yakuake thunderbird \
  gnome-mahjongg gnome-mines gnome-sudoku || true

sudo apt autoremove -y
sudo apt autoclean -y

echo "[2] Cleanup completed."

# -------------------------------------------------------
# 3) FULL SYSTEM UPDATE BEFORE INSTALLATION
# -------------------------------------------------------
echo "[3] Updating system..."
sudo apt update
sudo apt upgrade -y

# -------------------------------------------------------
# 4) ADD CUSTOM REPOSITORIES (PPAs)
# -------------------------------------------------------
echo "[4] Adding custom repositories and third-party apps..."

## Kisak Mesa
if ! grep -Rq "kisak/kisak-mesa" /etc/apt/; then
    echo " → Kisak Mesa (PPA)"
    sudo add-apt-repository -y ppa:kisak/kisak-mesa
fi

## Funkcija za pouzdanu DEB instalaciju
install_deb() {
    local URL=$1
    local FILENAME=$2
    local TMP_DEB="/tmp/$FILENAME.deb"

    echo " → $FILENAME (.deb install)"
    (
        # Preuzimanje: ako ne uspije, izlazak iz podshell-a s greškom
        wget -O "$TMP_DEB" "$URL" || { echo "ERROR: Failed to download $FILENAME DEB." >&2; exit 1; }
        
        # Instalacija i automatsko rješavanje ovisnosti (apt -f install)
        sudo apt install -y "$TMP_DEB" || sudo apt -f install -y
        
        rm -f "$TMP_DEB"
    )
}

# Primjena funkcije:
install_deb "https://mega.nz/linux/repo/xUbuntu_24.04/amd64/megasync-xUbuntu_24.04_amd64.deb" "megasync"
# install_deb "https://download.qnap.com/Storage/Utility/QfinderPro_Linux.deb" "qfinder"
install_deb "https://code-industry.net/public/master-pdf-editor-5.9.60-qt5.x86_64.deb" "masterpdf"


## VScode
echo " → Adding VSCode repo"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor \
    | sudo tee /usr/share/keyrings/ms_vscode.gpg >/dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ms_vscode.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

echo "[4] Repositories added."

# -------------------------------------------------------
# 5) REFRESH APT AFTER REPOS
# -------------------------------------------------------
echo "[5] Refreshing APT after adding repositories..."
sudo apt update

# -------------------------------------------------------
# 6) RUN APT INSTALLER SCRIPT
# -------------------------------------------------------
echo "[6] Installing APT packages..."
bash "$REPO_DIR/apt/install.sh"

# -------------------------------------------------------
# 7) RUN FLATPAK INSTALLER SCRIPT
# -------------------------------------------------------
echo "[7] Installing Flatpak packages..."

# Guarantee flathub is added
if ! flatpak remotes | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

flatpak uninstall --unused -y || true
bash "$REPO_DIR/flatpak/install.sh"


# -------------------------------------------------------
# 8) ZSH and POWERLEVEL10K INSTALL
# -------------------------------------------------------
echo "[8] Installing Zsh, zsh4humans, and Powerlevel10k..."
if [ -f "$REPO_DIR/languages/install_zsh.sh" ]; then
    bash "$REPO_DIR/languages/install_zsh.sh"
else
    echo "WARNING: install_zsh.sh not found. Skipping Zsh installation."
fi

# -------------------------------------------------------
# 9) LANGUAGE/ENVIRONMENT INSTALLS (Go, rbenv, Conda)
# -------------------------------------------------------
echo "[9] Installing language environments (Go, Ruby, Conda)..."

echo " → Running install_go.sh"
bash "$REPO_DIR/languages/install_go.sh"

echo " → Running install_rbenv.sh"
bash "$REPO_DIR/languages/install_rbenv.sh"

# echo " → Running install_conda.sh"
# bash "$REPO_DIR/languages/install_conda.sh"

# -------------------------------------------------------
# 10) RESTORE DOTFILES
# -------------------------------------------------------
if [ -d "$REPO_DIR/dotfiles" ]; then
    echo "[10] Restoring dotfiles..."
    # Korištenje -T za kopiranje Sadržaja izvora u odredište
    cp -rT "$REPO_DIR/dotfiles" "$HOME/"
fi


# -------------------------------------------------------
# 10a) RESTORE DESKTOP CONFIG (COSMIC / Kitty)
# -------------------------------------------------------
if [ -d "$REPO_DIR/cosmic" ]; then
    echo "[10a] Restoring COSMIC settings..."
    mkdir -p "$HOME/.config/cosmic"
    cp -rT "$REPO_DIR/cosmic" "$HOME/.config/cosmic/"
fi

echo "[10b] Installing Kitty configuration..."
mkdir -p "$HOME/.config/kitty"
cp -rT "$REPO_DIR/kitty" "$HOME/.config/kitty/"


# -------------------------------------------------------
# 11) WALLPAPER
# -------------------------------------------------------
echo "[11] Installing wallpapers..."

WALL="$REPO_DIR/wallpapers/jutro 4K.jpg"
TARGET="$HOME/Slike/Wallpaper/jutro 4K.jpg"

if [ -f "$WALL" ]; then
    echo " → Setting desktop wallpaper..."
    mkdir -p "$HOME/Slike/Wallpaper"
    cp "$WALL" "$TARGET"

    # GNOME / COSMIC wallpaper set (treba aktivnu sesiju da bi odmah radilo)
    gsettings set org.gnome.desktop.background picture-uri "file://$TARGET"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$TARGET"
else
    echo "WARNING: Wallpaper file not found at $WALL. Skipping wallpaper setup."
fi


# -------------------------------------------------------
# 12) FINAL CLEANUP
# -------------------------------------------------------
echo "[12] Final cleanup..."
sudo apt autoremove -y
sudo apt autoclean -y
flatpak uninstall --unused -y || true

echo "====================================================="
echo "     POSTINSTALL COMPLETE"
echo "====================================================="
echo "Please restart your system or run:  source ~/.zshrc (nakon re-loga)"