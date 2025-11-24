#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# System Packages, CLI Tools, and COPR Packages
###############################################################################
# This script installs essential CLI tools, system utilities, and ublue COPR packages
# Following bluefin pattern: Fedora packages first (bulk), then COPR packages (isolated)
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Fedora Packages (Bulk Installation)"

# Base packages from Fedora repos - common to all versions
FEDORA_PACKAGES=(
    # Development Tools
    make
    python3-pip
    python3-pygit2
    git-credential-libsecret

    # Shells & Terminal
    zsh
    ugrep
    bat
    atuin
    zoxide

    # System Utilities
    gum
    zenity
    powertop
    lm_sensors
    bcache-tools
    ddcutil
    evtest
    input-remapper

    # Hardware & Networking
    igt-gpu-tools
    switcheroo-control
    foo2zjs
    ifuse
    tailscale
    iwd
    waypipe

    # Filesystems & Storage
    gvfs-nfs
    gvfs-mtp
    rclone
    chezmoi
    fuse-encfs
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
    msedit
    fontawesome-fonts
    fontawesome-fonts-web
    adwaita-icon-theme
)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install --skip-unavailable "${FEDORA_PACKAGES[@]}"

echo "::endgroup::"

echo "Installing wf-recorder for screen recording..."
dnf5 install -y wf-recorder

echo "Installing slurp from thrnciar/setuptools-78.1.1..."
copr_install_isolated "thrnciar/setuptools-78.1.1" "slurp"

echo "::group:: Docker CE"

echo "Installing Docker CE..."
dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --skip-unavailable --enablerepo='docker-ce-stable' docker-ce docker-ce-cli docker-compose-plugin

echo "Configuring Docker CE..."
# Enable SSH agent globally
systemctl enable --global ssh-agent

# Create docker-compose symlink
ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Enable IP forwarding for Docker
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" > /usr/lib/sysctl.d/docker-ce.conf

# Configure Docker service presets
sed -i 's/enable docker/disable docker/' /usr/lib/systemd/system-preset/90-default.preset
systemctl preset docker.service docker.socket

# Create docker group
cat > /usr/lib/sysusers.d/docker.conf <<'EOF'
g docker -
EOF

systemctl enable --global tailscaled

echo "::endgroup::"

echo "::group:: Package Exclusions"

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    firefox
    firefox-langpacks
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software-rpm-ostree
    gnome-terminal-nautilus
    podman-docker
    yelp
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

echo "::group:: ublue COPR Packages"

echo "Installing ublue COPR packages..."

# Package swaps with ublue COPR
echo "Swapping fwupd with ublue-os packages version..."
copr_install_isolated "ublue-os/packages" "fwupd"

# Install ublue packages
echo "Installing ublue packages..."
copr_install_isolated "ublue-os/packages" \
    "ublue-brew" \
    "ublue-polkit-rules" \
    "ublue-setup-services" \
    "uupd" \
    "ublue-os-udev-rules" \
    "ublue-bling"

copr_install_isolated "trixieua/morewaita-icon-theme" "morewaita-icon-theme"
copr_install_isolated "zirconium/packages" "cliphist"

echo "::endgroup::"

echo "::group:: Configure ublue-brew"

echo "Configuring ublue-brew integration..."

# Fix critical symlink issue for ublue-brew
# Create tmpfiles entry to ensure symlink is created on boot
# The brew-setup.service doesn't create the essential symlink from
# /home/linuxbrew/.linuxbrew to /var/home/linuxbrew/.linuxbrew
echo "Adding symlink fix to brew-setup.service..."

cat > /usr/lib/tmpfiles.d/brew-symlink.conf <<'EOF'
# Create the essential symlink for Homebrew on boot
d /home 0755 - - -
d /var/home 0755 - - -
L /home/linuxbrew/.linuxbrew - - - - /var/home/linuxbrew/.linuxbrew
EOF

# Create environment file to add brew to PATH
cat > /etc/profile.d/brew.sh <<'EOF'
# Homebrew environment setup
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
    export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
    export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
fi
EOF

# Enable uupd.timer (brew-setup.service is already enabled by ublue-brew package)
echo "Enabling uupd.timer..."
systemctl enable uupd.timer || echo "uupd.timer already enabled or not found"

# Configure uupd to disable distrobox module (following Zirconium pattern)
if [ -f "/usr/lib/systemd/system/uupd.service" ]; then
    echo "Configuring uupd service..."
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
    echo "uupd configured to disable distrobox module"
fi

# Add brew path to sudoers for system-wide access
sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

echo "ublue-brew configured successfully"
echo "::endgroup::"

echo "System packages, CLI tools, and COPR packages installation complete!"
