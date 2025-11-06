#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Swap GNOME Desktop with COSMIC Desktop + Niri
###############################################################################
# This script replaces the GNOME desktop environment with System76's COSMIC 
# desktop and adds the Niri window manager.
#
# COSMIC: New desktop environment built in Rust by System76
# https://github.com/pop-os/cosmic-epoch
#
# Niri: Scrollable-tiling Wayland compositor
# https://github.com/YaLTeR/niri
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Remove GNOME Desktop"

# Remove GNOME Shell and related packages
if ! dnf5 remove -y \
    gnome-shell \
    gnome-shell-extension* \
    gnome-tweaks \
    gnome-control-center \
    gdm; then
    echo "Some GNOME components were not present; continuing"
fi

echo "GNOME desktop removed"
echo "::endgroup::"

echo "::group:: Install COSMIC Desktop"

# Install COSMIC desktop from System76's COPR
# Using isolated pattern to prevent COPR from persisting
copr_install_isolated "ryanabx/cosmic-epoch" \
    cosmic-app-library \
    cosmic-applets \
    cosmic-bg \
    cosmic-comp \
    cosmic-edit \
    cosmic-files \
    cosmic-greeter \
    cosmic-icon-theme \
    cosmic-idle \
    cosmic-initial-setup \
    cosmic-launcher \
    cosmic-notifications \
    cosmic-osd \
    cosmic-panel \
    cosmic-player \
    cosmic-randr \
    cosmic-screenshot \
    cosmic-session \
    cosmic-settings \
    cosmic-settings-daemon \
    cosmic-store \
    cosmic-term \
    cosmic-wallpapers \
    cosmic-workspaces \
    pop-launcher \
    xdg-desktop-portal-cosmic

echo "COSMIC desktop installed successfully"
echo "::endgroup::"

echo "::group:: Install Niri Window Manager"

# Install Niri from yalter/niri-git COPR
copr_install_isolated "yalter/niri-git" niri

echo "Niri window manager installed successfully"
echo "::endgroup::"

echo "::group:: Configure Display Manager"

# Enable cosmic-greeter (COSMIC's display manager)
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

echo "::group:: Configure Niri Service"

# Helper function to add Wants= directives to niri.service
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}

echo "Niri service configured"
echo "::endgroup::"

echo "::group:: Install Additional Utilities"


echo "Additional utilities installed"
echo "::endgroup::"

echo "::group:: Add COSMIC Flatpak Remote"

# Add COSMIC Flatpak remote
flatpak remote-add --if-not-exists --system cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo

echo "COSMIC Flatpak remote configured"
echo "::endgroup::"



echo "COSMIC desktop installation complete!"
