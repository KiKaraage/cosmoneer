#!/usr/bin/bash

set -eoux pipefail

# Install packages from Fedora repos
echo "===$(basename "$0")==="

echo "::group:: Bulk installing Fedora packages"

FEDORA_PACKAGES=(
    # Shells & Terminal
    # zsh
    # ugrep
    # bat
    # atuin
    # zoxide

    # Development Tools
    make
    python3-pip
    python3-pygit2
    git-credential-libsecret

    # System Utilities
    # gum
    # zenity
    powertop
    # lm_sensors
    bcache-tools
    # ddcutil
    evtest
    input-remapper

    # Hardware & Networking
    igt-gpu-tools
    libcamera-v4l2
    switcheroo-control
    foo2zjs
    ifuse
    tailscale
    iwd
    waypipe

    # Filesystems & Storage
    gvfs-nfs
    gvfs-mtp
    gvfs-smb
    fuse-devel
    fuse-encfs
    # rclone
    # chezmoi
    davfs2
    jmtpfs

    # Security & Keyring
    gnome-keyring
    gnome-keyring-pam

    # Desktop & Display
    brightnessctl
    nautilus
    swayidle

    # Additional Packages
    ibus-mozc
    libxcrypt-compat
    setools-console
    usbip
    openssh-askpass
    oddjob-mkhomedir

    # Others
    fontawesome-fonts
    fontawesome-fonts-web
    wf-recorder
    vte291-gtk4-devel
)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install --skip-unavailable "${FEDORA_PACKAGES[@]}"

echo "::endgroup::"

echo "::group:: Bulk remove excluded Fedora packages"

# Fedora packages to exclude
EXCLUDED_PACKAGES=(
    fedora-bookmarks
    fedora-chromium-config
    firefox
    firefox-langpacks
)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

echo "::endgroup::"

echo "::group:: Install OpenCode & Wave Terminal"

echo "Installing latest OpenCode RPM..."
cd /tmp
curl -L -o oc.rpm "https://github.com/sst/opencode/releases/latest/download/opencode-desktop-linux-x86_64.rpm"
dnf5 install -y ./oc.rpm
rm -f oc.rpm

echo "Installing latest Wave Terminal RPM..."
# Get the latest Wave Terminal release RPM URL
WAVE_URL=$(curl -s "https://api.github.com/repos/wavetermdev/waveterm/releases/latest" | grep "browser_download_url.*waveterm-linux-x86_64.*\.rpm" | cut -d '"' -f 4)
curl -L -o wave.rpm "$WAVE_URL"
dnf5 install -y ./wave.rpm
rm -f wave.rpm

echo "::endgroup::"
