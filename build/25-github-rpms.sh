#!/usr/bin/env bash
set -oue pipefail

###############################################################################
# Install GitHub Release RPMs with Evergreen URLs
###############################################################################

echo "Installing Crystal Dock..."
# Download and install Crystal Dock (latest release)
curl -L -o /tmp/crystal-dock.rpm "https://github.com/dangvd/crystal-dock/releases/latest/download/crystal-dock-$(curl -s https://api.github.com/repos/dangvd/crystal-dock/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4 | sed 's/v//')-1.x86_64.rpm"
dnf5 install -y /tmp/crystal-dock.rpm
rm -f /tmp/crystal-dock.rpm

echo "Installing qt6ct..."
# Install qt6ct from Fedora repos
dnf5 install -y qt6ct

echo "Installing WaveTerminal..."
# Download and install WaveTerminal (latest release)
WAVE_VERSION=$(curl -s https://api.github.com/repos/wavetermdev/waveterm/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
curl -L -o /tmp/waveterm.rpm "https://github.com/wavetermdev/waveterm/releases/download/$WAVE_VERSION/waveterm-linux-x86_64-${WAVE_VERSION#v}.rpm"
dnf5 install -y /tmp/waveterm.rpm
rm -f /tmp/waveterm.rpm

echo "Installing additional utilities..."
# Install packages moved from 30-cosmic-desktop.sh
dnf5 install -y \
    msedit \
    brightnessctl \
    fontawesome-fonts \
    fontawesome-fonts-web

echo "Setting up Qt6 platform theme..."
# Add QT_QPA_PLATFORMTHEME to environment
echo "QT_QPA_PLATFORMTHEME=qt6ct" >> /etc/environment

echo "Crystal Dock, qt6ct, WaveTerminal, and additional utilities installation complete!"