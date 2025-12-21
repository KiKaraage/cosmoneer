#!/usr/bin/bash

set -eoux pipefail

# Universal Blue Packages - COPR, Brew, Autoupdater

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "===$(basename "$0")==="


echo "::group:: ublue COPR Packages"

echo "Installing ublue COPR packages..."

# Install ublue packages
copr_install_isolated "ublue-os/packages" \
    "ublue-polkit-rules" \
    "ublue-setup-services" \
    "uupd" \
    "ublue-bling"

systemctl enable uupd.timer || echo "uupd.timer already enabled or not found"
systemctl enable brew-setup.service || echo "Brew setup is already done, or not found"

# Configure uupd to disable distrobox module
if [ -f "/usr/lib/systemd/system/uupd.service" ]; then
    echo "Configuring uupd service..."
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
    echo "uupd configured to disable distrobox module"
fi

# Make sure essential directories exist
# Create parent directories first to avoid issues when creating specific user directories
# mkdir -p /var/home
# mkdir -p /home
# mkdir -p /var/home/linuxbrew
# mkdir -p /home/linuxbrew
# chown 1000:1000 /var/home/linuxbrew

# Ensure the homebrew tarball exists (this should be part of the package)
# if [ ! -f "/usr/share/homebrew.tar.zst" ]; then
#     echo "Error: /usr/share/homebrew.tar.zst not found"
#     exit 1
# fi

# Ensure the marker file does not exist so the service will run (this is part of service conditions)
# rm -f /etc/.linuxbrew

# Create environment file to add brew to PATH (still needed since service doesn't do this)
# cat > /etc/profile.d/brew.sh <<'EOF'
# Homebrew environment setup
# if [ -d "/home/linuxbrew/.linuxbrew" ]; then
#     export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
#     export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
#     export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
# fi
# EOF

# Add brew path to sudoers for system-wide access (still needed)
# sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers

# echo "ublue-brew configured successfully"
# echo "::endgroup::"
