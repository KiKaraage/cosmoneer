#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Configure Niri Session Services and Portal System Configuration
###############################################################################
# This script configures essential services for the niri session and portal services system-wide
###############################################################################

echo "::group:: Configure Portal Services"

# Ensure GTK portal is not masked (build-time mask removal)
mkdir -p "/etc/systemd/user"
rm -f "/etc/systemd/user/xdg-desktop-portal-gtk.service" || true

# Enable GTK portal for file chooser in Niri
mkdir -p "/etc/systemd/user/graphical-session.target.wants"
ln -sf "/usr/lib/systemd/user/xdg-desktop-portal-gtk.service" \
    "/etc/systemd/user/graphical-session.target.wants/xdg-desktop-portal-gtk.service" || true

echo "::endgroup::"
echo "::group:: Configure Niri Session Services"

# Configure waybar service
if [ -f "/usr/lib/systemd/user/waybar.service" ]; then
    mkdir -p "/usr/lib/systemd/user/niri.service.wants"
    ln -sf "/usr/lib/systemd/user/waybar.service" "/usr/lib/systemd/user/niri.service.wants/waybar.service" || true
fi

# Configure cliphist service
if [ -f "/usr/lib/systemd/user/cliphist.service" ]; then
    mkdir -p "/usr/lib/systemd/user/niri.service.wants"
    ln -sf "/usr/lib/systemd/user/cliphist.service" "/usr/lib/systemd/user/niri.service.wants/cliphist.service" || true
fi

# Disable cosmic-idle (not compatible with Niri)
if [ -f "/usr/lib/systemd/user/cosmic-idle.service" ]; then
    rm -f "/etc/systemd/user/graphical-session.target.wants/cosmic-idle.service" || true
    mkdir -p "/etc/systemd/user"
    ln -sf "/dev/null" "/etc/systemd/user/cosmic-idle.service" || true
fi

echo "::endgroup::"