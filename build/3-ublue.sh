#!/usr/bin/bash
set -eoux pipefail

echo "===$(basename "$0")==="
echo "::group:: Universal Blue Services Setup"

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "COPR packages skipped - using OCI images for brew"
copr_install_isolated "ublue-os/packages" \
    "ublue-os-udev-rules" \
    "uupd"

echo "::group:: Configure ublue-brew Integration"

echo "NOTE: Using OCI images - directory setup handled automatically"

# Make sure essential directories exist
# Create parent directories first to avoid issues when creating specific user directories
# NOTE: These directories are now created by OCI images
# mkdir -p /var/home
# mkdir -p /home
# mkdir -p /var/home/linuxbrew
# mkdir -p /home/linuxbrew
# chown 1000:1000 /var/home/linuxbrew

# Ensure the homebrew tarball exists (should come from OCI image)
if [ ! -f "/usr/share/homebrew.tar.zst" ]; then
    echo "Warning: /usr/share/homebrew.tar.zst not found - should be provided by OCI image"
    echo "This might indicate the brew OCI image is not properly copied"
fi

# Ensure the marker file does not exist so the service will run (this is part of service conditions)
# NOTE: This should be handled by the OCI image
# rm -f /etc/.linuxbrew

# Configure uupd to disable distrobox module
if [ -f "/usr/lib/systemd/system/uupd.service" ]; then
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
    echo "uupd configured to disable distrobox module"
fi

# Enable services (done after OCI files are copied in Containerfile)
# systemctl enable brew-setup.service || echo "brew-setup.service already enabled"
# systemctl enable brew-upgrade.timer || echo "brew-upgrade.timer already enabled"
# systemctl enable brew-update.timer || echo " brew-update.timer already enabled"
systemctl enable uupd.timer || echo "uupd.timer already enabled or not found"

# Create environment file to add brew to PATH (should come from OCI)
# NOTE: This should be provided by the brew OCI image
# cat > /etc/profile.d/brew.sh <<'EOF'
# # Homebrew environment setup
# if [ -d "/home/linuxbrew/.linuxbrew" ]; then
#     export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
#     export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
#     export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
# fi
# EOF

# Add brew path to sudoers for system-wide access (should come from OCI)
# NOTE: This should be handled by the OCI image
# sed -Ei "s/secure_path = (.*)/secure_path = \\1:\\/home\\/linuxbrew\\/.linuxbrew\\/bin/" /etc/sudoers

echo "::endgroup::"

echo "::endgroup::"
