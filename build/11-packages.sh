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
    jq
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
    wf-recorder
)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf5 -y install --skip-unavailable "${FEDORA_PACKAGES[@]}"

echo "::endgroup::"

echo "::group:: Install 3rd-party COPR packages"

echo "Installing Morewaita icon theme..."
copr_install_isolated "trixieua/morewaita-icon-theme" "morewaita-icon-theme"
echo "Installing cliphist..."
copr_install_isolated "zirconium/packages" "cliphist"
echo "Installing slurp..."
copr_install_isolated "thrnciar/setuptools-78.1.1" "slurp"

echo "::endgroup::"

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

echo "::endgroup::"

echo "::group:: Configure ublue-brew"

echo "Configuring ublue-brew integration..."

# Make sure essential directories exist
# Create parent directories first to avoid issues when creating specific user directories
mkdir -p /var/home
mkdir -p /home
mkdir -p /var/home/linuxbrew
mkdir -p /home/linuxbrew
chown 1000:1000 /var/home/linuxbrew

# Ensure the homebrew tarball exists (this should be part of the package)
if [ ! -f "/usr/share/homebrew.tar.zst" ]; then
    echo "Error: /usr/share/homebrew.tar.zst not found"
    exit 1
fi

# Ensure the marker file does not exist so the service will run (this is part of service conditions)
rm -f /etc/.linuxbrew

# Enable services
echo "Enabling brew-setup and uupd services..."
systemctl enable brew-setup.service || echo "brew-setup.service already enabled"
systemctl enable uupd.timer || echo "uupd.timer already enabled or not found"

# Configure uupd to disable distrobox module (following Zirconium pattern)
if [ -f "/usr/lib/systemd/system/uupd.service" ]; then
    echo "Configuring uupd service..."
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
    echo "uupd configured to disable distrobox module"
fi

# Create environment file to add brew to PATH (still needed since service doesn't do this)
cat > /etc/profile.d/brew.sh <<'EOF'
# Homebrew environment setup
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
    export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
    export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
fi
EOF

# Add brew path to sudoers for system-wide access (still needed)
sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

echo "ublue-brew configured successfully"
echo "::endgroup::"

echo "::group:: Verify Brew Installation Post-Configuration"

# Check that brew-setup service is enabled
if systemctl is-enabled brew-setup.service 2>/dev/null; then
    echo "✓ brew-setup.service is enabled"
else
    echo "⚠ brew-setup.service is not enabled"
fi

# Check if homebrew tarball exists
if [ -f "/usr/share/homebrew.tar.zst" ]; then
    echo "✓ homebrew.tar.zst exists"
else
    echo "⚠ homebrew.tar.zst does not exist"
fi

# The actual symlink will be created when the system boots for the first time
echo "Note: Symlink /home/linuxbrew/.linuxbrew will be created by brew-setup.service at first boot"
echo "::endgroup::"

echo "Enable Tailscale daemon service"
systemctl enable tailscaled || echo "Can't enable Tailscale daemon service"

echo "::group:: Install OpenCode Desktop"

echo "Installing latest OpenCode Desktop RPM..."
# Download and install to handle GitHub redirects properly
cd /tmp
curl -L -o opencode-desktop.rpm "https://github.com/sst/opencode/releases/latest/download/opencode-desktop-linux-x86_64.rpm"
dnf5 install -y ./opencode-desktop.rpm
rm -f opencode-desktop.rpm

echo "::endgroup::"

echo "System packages, CLI tools, and COPR packages installation complete!"
