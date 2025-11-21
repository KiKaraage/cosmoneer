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

# Install cliphist from zirconium COPR (if available)
echo "Installing cliphist from zirconium packages..."
copr_install_isolated "zirconium/packages" "cliphist" || echo "cliphist not available, skipping"

echo "::endgroup::"

echo "::group:: Configure ublue-brew"

echo "Configuring ublue-brew integration..."

# Fix critical symlink issue for ublue-brew
# The brew-setup.service doesn't create the essential symlink from
# /home/linuxbrew/.linuxbrew to /var/home/linuxbrew/.linuxbrew
echo "Adding symlink fix to brew-setup.service..."
if [ -f "/usr/lib/systemd/system/brew-setup.service" ]; then
    # Create a drop-in to add the symlink fix
    mkdir -p /usr/lib/systemd/system/brew-setup.service.d
    cat > /usr/lib/systemd/system/brew-setup.service.d/symlink-fix.conf <<'EOF'
[Service]
ExecStartPost=/usr/bin/ln -sf /var/home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew
EOF
    echo "Symlink fix added to brew-setup.service"
else
    echo "Warning: brew-setup.service not found, symlink fix skipped"
fi

# Enable ublue-brew services
echo "Enabling ublue-brew services..."
systemctl enable brew-setup.service || echo "brew-setup.service already enabled or not found"
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
