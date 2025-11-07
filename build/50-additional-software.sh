#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Additional Software and External RPMs
###############################################################################
# This script installs additional software from dnf5 and external RPM sources
###############################################################################

echo "::group:: Install Hardware and Networking Packages"

echo "Installing hardware support packages..."
dnf5 install -y \
    igt-gpu-tools \
    switcheroo-control

echo "Installing printer drivers..."
dnf5 install -y \
    foo2zjs

echo "Installing mobile device support..."
dnf5 install -y \
    ifuse

echo "Installing networking tools..."
dnf5 install -y \
    tailscale \
    iwd \
    waypipe

echo "Installing additional utilities..."
dnf5 install -y \
    msedit \
    fontawesome-fonts \
    fontawesome-fonts-web

echo "Enabling Tailscale service..."
systemctl enable tailscaled

echo "::endgroup::"

echo "::group:: Install GitHub Release RPMs"

echo "::group:: Installing Crystal Dock"
echo "Downloading Crystal Dock..."
# Download Crystal Dock (latest release)
CRYSTAL_VERSION=$(curl -s https://api.github.com/repos/dangvd/crystal-dock/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4 | sed 's/v//')
echo "Crystal Dock version: $CRYSTAL_VERSION"
echo "Fetching crystal-dock-${CRYSTAL_VERSION}-1.x86_64.rpm..."
curl -L -o /tmp/crystal-dock.rpm "https://github.com/dangvd/crystal-dock/releases/latest/download/crystal-dock-${CRYSTAL_VERSION}-1.x86_64.rpm"
echo "Installing Crystal Dock RPM..."
dnf5 install -y /tmp/crystal-dock.rpm
rm -f /tmp/crystal-dock.rpm
echo "Crystal Dock installed successfully"
echo "::endgroup::"

echo "::group:: Installing WaveTerminal"
echo "Downloading WaveTerminal..."
# Download WaveTerminal (latest release)
WAVE_VERSION=$(curl -s https://api.github.com/repos/wavetermdev/waveterm/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
echo "WaveTerminal version: ${WAVE_VERSION#v}"
echo "Fetching waveterm-linux-x86_64-${WAVE_VERSION#v}.rpm..."
curl -L -o /tmp/waveterm.rpm "https://github.com/wavetermdev/waveterm/releases/download/$WAVE_VERSION/waveterm-linux-x86_64-${WAVE_VERSION#v}.rpm"
echo "Installing WaveTerminal RPM..."
dnf5 install -y /tmp/waveterm.rpm
rm -f /tmp/waveterm.rpm
echo "WaveTerminal installed successfully"
echo "::endgroup::"

echo "::group:: Installing Qt6 Theme Configuration"
# Install qt6ct from Fedora repos
echo "Checking qt6ct availability..."
QT6CT_VERSION=$(dnf5 info qt6ct | grep -E "^Version[[:space:]]*:" | awk '{print $3}')
echo "qt6ct version: $QT6CT_VERSION"
echo "Installing qt6ct for Qt6 application theming..."
dnf5 install -y qt6ct
echo "qt6ct installed successfully"
echo "::endgroup::"

echo "::group:: Configuring Qt6 Platform Theme"
# Add QT_QPA_PLATFORMTHEME to environment
echo "Setting QT_QPA_PLATFORMTHEME=qt6ct in /etc/environment..."
echo "QT_QPA_PLATFORMTHEME=qt6ct" >> /etc/environment
echo "Qt6 platform theme configured - Qt6 applications will now use qt6ct for theming"
echo "::endgroup::"

echo "::endgroup::"

echo "Additional software installation complete!"