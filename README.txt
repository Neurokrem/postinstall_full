Postinstall skeleton for Pop!_OS (COSMIC)
Structure:

apt/install.sh : installs APT packages (from your manual.txt)

flatpak/install.sh : installs Flatpak apps (from your flatpak.txt)

languages/ : installers for Go (tar.gz), rbenv and Anaconda (full)

dotfiles/ : place your dotfiles here (.zshrc, .p10k.zsh, etc.)

cosmic/ : place COSMIC config folders here to restore

wallpapers/ : put default.jpg here to copy as wallpaper

postinstall.sh : orchestrator - run this from within the repo folder
Usage:

Put your dotfiles into dotfiles/ and COSMIC config into cosmic/

cd ~/postinstall_full && ./postinstall.sh
Notes:

Review scripts before running. They will run apt, flatpak, download binaries and require sudo.

The scripts append PATHs only if missing and are mostly idempotent.