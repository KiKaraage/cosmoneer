#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Configure Niri Session Services and Portal System Configuration
###############################################################################
# This script configures essential services for the niri session and portal services system-wide
###############################################################################

echo "::group:: Configure Portal Services"

# Ensure GTK portal is enabled for Niri file chooser dialogs
mkdir -p "/etc/systemd/user/graphical-session.target.wants"
if [ -f "/usr/lib/systemd/user/xdg-desktop-portal-gtk.service" ]; then
    ln -sf "/usr/lib/systemd/user/xdg-desktop-portal-gtk.service" \
        "/etc/systemd/user/graphical-session.target.wants/xdg-desktop-portal-gtk.service"
fi

echo "::endgroup::"