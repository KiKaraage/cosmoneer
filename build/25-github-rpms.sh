#!/usr/bin/env bash
set -oue pipefail

###############################################################################
# Install GitHub Release RPMs and Additional Utilities
###############################################################################

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

echo "::group:: Installing Qt6 Theme Configuration"
# Install qt6ct from Fedora repos
echo "Checking qt6ct availability..."
QT6CT_VERSION=$(dnf5 info qt6ct | grep -E "^Version[[:space:]]*:" | awk '{print $3}')
echo "qt6ct version: $QT6CT_VERSION"
echo "Installing qt6ct for Qt6 application theming..."
dnf5 install -y qt6ct
echo "qt6ct installed successfully"
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

echo "::group:: Installing Additional Utilities"
echo "Checking package versions..."
MSEDIT_VERSION=$(dnf5 info msedit 2>/dev/null | grep -E "^Version[[:space:]]*:" | awk '{print $3}' || echo "unknown")
BRIGHTNESSCTL_VERSION=$(dnf5 info brightnessctl 2>/dev/null | grep -E "^Version[[:space:]]*:" | awk '{print $3}' || echo "unknown")
FONTAWESOME_VERSION=$(dnf5 info fontawesome-fonts 2>/dev/null | grep -E "^Version[[:space:]]*:" | awk '{print $3}' || echo "unknown")
echo "msedit version: $MSEDIT_VERSION"
echo "brightnessctl version: $BRIGHTNESSCTL_VERSION"
echo "fontawesome-fonts version: $FONTAWESOME_VERSION"
echo "Installing additional utilities:"
echo "  - msedit (text editor)"
echo "  - brightnessctl (brightness control)"
echo "  - fontawesome-fonts (icon fonts)"
echo "  - fontawesome-fonts-web (web icon fonts)"
dnf5 install -y \
    msedit \
    brightnessctl \
    fontawesome-fonts \
    fontawesome-fonts-web
echo "Additional utilities installed successfully"
echo "::endgroup::"

echo "::group:: Configuring Qt6 Platform Theme"
# Add QT_QPA_PLATFORMTHEME to environment
echo "Setting QT_QPA_PLATFORMTHEME=qt6ct in /etc/environment..."
echo "QT_QPA_PLATFORMTHEME=qt6ct" >> /etc/environment
echo "Qt6 platform theme configured - Qt6 applications will now use qt6ct for theming"
echo "::endgroup::"

echo "All GitHub RPM installations and configurations completed successfully!"