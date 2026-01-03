#!/usr/bin/bash
set -eoux pipefail

echo "===$(basename "$0")==="
echo "::group:: Install COSMIC Desktop"

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Install COSMIC desktop packages
copr_install_isolated "ryanabx/cosmic-epoch" cosmic-desktop
echo "COSMIC desktop installed successfully"

# Add COSMIC Flatpak repo for applet downloads
flatpak remote-add --if-not-exists --system cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo
echo "COSMIC Flatpak remote configured"

echo "::endgroup::"

echo "::group:: Configure Display Manager"

# Enable cosmic-greeter
systemctl enable cosmic-greeter

# Set COSMIC as default session
mkdir -p /etc/X11/sessions
cat > /etc/X11/sessions/cosmic.desktop << 'COSMICDESKTOP'
[Desktop Entry]
Name=COSMIC
Comment=COSMIC Desktop Environment
Exec=cosmic-session
Type=Application
DesktopNames=COSMIC
COSMICDESKTOP

echo "Display manager configured"
echo "::endgroup::"

echo "::group:: Enable GNOME Keyring Services"

# Create user preset to enable GNOME Keyring for all users
mkdir -p /etc/systemd/user-preset.d
cat > /etc/systemd/user-preset.d/00-gnome-keyring.preset << 'EOF'
[Install]
gnome-keyring-daemon.socket=yes
gnome-keyring-daemon.service=yes
EOF

# Enable GNOME Keyring services system-wide for all users
systemctl --global enable gnome-keyring-daemon.socket || echo "Failed to globally enable gnome-keyring-daemon.socket"
systemctl --global enable gnome-keyring-daemon.service || echo "Failed to globally enable gnome-keyring-daemon.service"

# Configure PAM for gnome-keyring integration with cosmic-greeter
if [ -f "/etc/pam.d/cosmic-greeter" ]; then
    echo "PAM configuration for cosmic-greeter found"
else
    echo "Warning: cosmic-greeter PAM configuration not found"
fi

echo "GNOME Keyring services enabled globally"
echo "::endgroup::"
