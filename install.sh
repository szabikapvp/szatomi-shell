#!/usr/bin/env bash
# szatomi-shell installer and updater. Run it again any time to update:
#   curl -fsSL https://raw.githubusercontent.com/szabikapvp/szatomi-shell/main/install.sh | bash
set -euo pipefail

REPO="${SZATOMI_REPO:-https://github.com/szabikapvp/szatomi-shell.git}"
BRANCH="${SZATOMI_BRANCH:-main}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELL_DIR="$CONFIG/quickshell"
STAMP="$(date +%Y%m%d-%H%M%S)"
MIN_HYPRLAND="0.56"

ARCH_PKGS=(
    git curl hyprland xdg-desktop-portal-hyprland quickshell qt6-svg
    hyprlock hyprpicker hyprshot kitty dolphin copyq kdeconnect
    pipewire wireplumber networkmanager bluez bluez-utils upower
    brightnessctl playerctl imagemagick python-pipx
)
FEDORA_PKGS=(
    git curl hyprland xdg-desktop-portal-hyprland quickshell qt6-qtsvg
    hyprlock hyprpicker hyprshot kitty dolphin copyq kde-connect
    pipewire wireplumber NetworkManager NetworkManager-wifi bluez upower
    brightnessctl playerctl ImageMagick pywal
)
# From the HyprCapture README, vtk and hdf5 only work around a build failure there
HYPRCAPTURE_PKGS=(
    base-devel cmake cpio nlohmann-json lua glib2 qt6-base qt6-svg qt6-wayland layer-shell-qt
    opencv vtk hdf5 libpipewire fftw libpulse ffmpeg wl-clipboard
)

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; exit 1; }
ask()  { local answer; read -rp "$1 [y/N] " answer; [[ $answer == [yY]* ]]; }
has()  { command -v "$1" >/dev/null 2>&1; }

detect_distro() {
    local ids
    ids="$(. /etc/os-release && echo " ${ID:-} ${ID_LIKE:-} ")"
    if has pacman; then echo arch
    elif has dnf && [[ $ids == *" fedora "* ]]; then echo fedora
    else die "Only Arch-based and Fedora-based distros are supported."
    fi
}

install_arch() {
    sudo pacman -Syu --needed "${ARCH_PKGS[@]}"
    has wal && return
    local aur
    aur="$(command -v paru || command -v yay || true)"
    if [[ -n $aur ]]; then "$aur" -S --needed python-pywal
    else sudo pipx install --global pywal
    fi
}

install_fedora() {
    sudo dnf install -y dnf-plugins-core
    sudo dnf copr enable -y nett00n/hyprland
    sudo dnf install -y --skip-unavailable "${FEDORA_PKGS[@]}"
}

# Clones the shell, or pulls it when it's already this repo
install_repo() {
    if git -C "$SHELL_DIR" remote get-url origin 2>/dev/null | grep 'szatomi-shell' >/dev/null; then
        say "Updating $SHELL_DIR"
        git -C "$SHELL_DIR" pull --ff-only origin "$BRANCH" \
            || die "Couldn't update: $SHELL_DIR has local changes. Commit or stash them, or put Hyprland tweaks in ~/.config/hypr/user.lua."
    else
        backup "$SHELL_DIR"
        say "Downloading szatomi-shell"
        git clone --branch "$BRANCH" "$REPO" "$SHELL_DIR"
    fi
}

backup() {
    [[ -e $1 || -L $1 ]] || return 0
    mv "$1" "$1.bak-$STAMP"
    say "Moved your old $1 to $1.bak-$STAMP"
}

# Points $1 at $2, so files added to the repo later come along on update
link() {
    [[ -L $1 && $1 -ef $2 ]] && return
    backup "$1"
    mkdir -p "$(dirname "$1")"
    ln -s "$2" "$1"
}

# Downloads a family's files from Google Fonts, unless it's already installed
install_font() {
    local family=$1 file
    shift
    fc-list | grep "$family" >/dev/null && return
    say "Installing the $family font"
    mkdir -p "$HOME/.local/share/fonts"
    for file in "$@"; do
        curl -fsSLo "$HOME/.local/share/fonts/${file##*/}" "https://github.com/google/fonts/raw/main/ofl/$file"
    done
    fc-cache -f >/dev/null
}

install_assets() {
    install_font "Space Grotesk" 'spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf'
    install_font "Dela Gothic One" delagothicone/DelaGothicOne-Regular.ttf
    install_font "Space Mono" spacemono/SpaceMono-{Regular,Bold,Italic,BoldItalic}.ttf
    if [[ ! -d $HOME/.local/share/icons/Bibata-Modern-Classic && ! -d /usr/share/icons/Bibata-Modern-Classic ]]; then
        say "Installing the Bibata cursor"
        mkdir -p "$HOME/.local/share/icons"
        curl -fsSL 'https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz' \
            | tar -xJ -C "$HOME/.local/share/icons"
    fi
    mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/screenshots"
}

# Enabled for the next boot, never started now, so a running connection isn't cut mid install
enable_services() {
    sudo systemctl enable bluetooth.service || warn "Couldn't enable Bluetooth."
    systemctl is-enabled --quiet NetworkManager.service && return
    local other
    for other in connman systemd-networkd iwd netctl; do
        if systemctl is-enabled --quiet "$other.service" 2>/dev/null; then
            warn "$other manages your network, so NetworkManager stays off. The Wi-Fi page needs NetworkManager running."
            return
        fi
    done
    sudo systemctl enable NetworkManager.service
}

install_hyprcapture() {
    hyprpm list 2>/dev/null | grep hyprcapture >/dev/null && return
    ask "Install HyprCapture (optional screenshot and recording plugin, slow to build)?" || return 0
    if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        warn "HyprCapture builds against the running Hyprland. Run the installer again from inside Hyprland."
        return
    fi
    sudo pacman -S --needed "${HYPRCAPTURE_PKGS[@]}"
    hyprpm update
    hyprpm add https://github.com/gfhdhytghd/HyprCapture
    hyprpm enable hyprcapture
    hyprpm reload
}

check_hyprland() {
    local version
    version="$(Hyprland --version 2>/dev/null || true)"
    version="${version#Hyprland }"
    version="${version%% *}"
    if [[ $(printf '%s\n' "$MIN_HYPRLAND" "$version" | sort -V | head -1) != "$MIN_HYPRLAND" ]]; then
        warn "Hyprland ${version:-not found} is older than $MIN_HYPRLAND, which can't read hyprland.lua."
    fi
}

# Reloads a running session, so an update shows up right away
reload_session() {
    [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0
    hyprctl reload >/dev/null
    qs kill -p "$SHELL_DIR" >/dev/null 2>&1 || true
    qs -p "$SHELL_DIR" -d >/dev/null 2>&1
}

main() {
    [[ $EUID -ne 0 ]] || die "Run this as your normal user, not root. It asks for sudo when it needs it."
    local distro
    distro="$(detect_distro)"

    say "Installing packages"
    "install_$distro"
    install_repo
    link "$CONFIG/hypr" "$SHELL_DIR/hypr"
    link "$CONFIG/kitty" "$SHELL_DIR/kitty"
    install_assets
    enable_services
    [[ $distro == arch ]] && install_hyprcapture
    check_hyprland
    reload_session

    say "Done. Log into Hyprland to start szatomi-shell, and run the same command again to update."
}

# Reads prompts from the terminal even when piped from curl. The whole file is parsed before main runs
main "$@" </dev/tty
exit
