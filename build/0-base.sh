#!/usr/bin/bash

set -eoux pipefail

# Base Image Setup + Custom File Copying

# Enable core system services
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service

# Configure systemd-resolved as default
echo "Configuring systemd-resolved..."
tee /usr/lib/systemd/system-preset/91-resolved-default.preset <<'EOF'
enable systemd-resolved.service
EOF
tee /usr/lib/tmpfiles.d/resolved-default.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF
systemctl preset systemd-resolved.service

echo "::group:: Copy Custom Files"

echo "Copying custom Brewfiles..."
# Copy Brewfiles to standard location
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/
echo "Brewfiles copied to /usr/share/ublue-os/homebrew/"

echo "Consolidating custom Just files..."
# Consolidate Just Files
mkdir -p /usr/share/ublue-os/just/
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /usr/share/ublue-os/just/60-custom.just
echo "Just files consolidated to /usr/share/ublue-os/just/60-custom.just"

echo "Copying Flatpak preinstall files..."
# Copy Flatpak preinstall files
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
echo "Flatpak preinstall files copied to /etc/flatpak/preinstall.d/"

echo "::endgroup::"

echo "::group:: System Configuration"

echo "Configuring systemd services..."
# Enable/disable systemd services
echo "Enabling podman.socket for container management..."
systemctl enable podman.socket
echo "podman.socket enabled successfully"

echo "::endgroup::"

echo "Base image configuration complete!"
