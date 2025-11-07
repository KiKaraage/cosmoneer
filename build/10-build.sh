#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

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

echo "::group:: Install Packages"

echo "No additional packages to install in main build script"
echo "Package installations are handled in specialized build scripts:"
echo "  - 25-github-rpms.sh (GitHub release RPMs)"
echo "  - 30-cosmic-desktop.sh (COSMIC desktop packages)"
echo "  - 35-cosmic-niri-ext.sh (Niri extensions)"

# Install packages using dnf5
# Example: dnf5 install -y tmux

# Example using COPR with isolated pattern:
# copr_install_isolated "ublue-os/staging" package-name

echo "::endgroup::"

echo "::group:: System Configuration"

echo "Configuring systemd services..."
# Enable/disable systemd services
echo "Enabling podman.socket for container management..."
systemctl enable podman.socket
echo "podman.socket enabled successfully"
# Example: systemctl mask unwanted-service

echo "::endgroup::"

echo "Custom build complete!"
