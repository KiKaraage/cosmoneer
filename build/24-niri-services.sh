#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Configure Niri Session Services and Portal System Configuration
###############################################################################
# This script configures essential services for the niri session and portal services system-wide
###############################################################################

echo "::group:: Configure Portal Services"

# Unmask and enable portal services
echo "Unmasking xdg-desktop-portal-gtk service..."
systemctl --user unmask xdg-desktop-portal-gtk.service || echo "xdg-desktop-portal-gtk.service already unmasked"

# Enable portal services globally for all users
echo "Enabling portal services globally..."
# Check if services exist before enabling
for service in xdg-desktop-portal-cosmic.service xdg-desktop-portal-gtk.service xdg-desktop-portal-gnome.service; do
    service_file="/usr/lib/systemd/user/${service}"
    if [ -f "$service_file" ]; then
        systemctl --global enable "$service" || echo "$service already enabled globally"
    else
        echo "$service not found, skipping"
    fi
done

echo "::endgroup::"

echo "::group:: Configure Niri Session Services"

# Enable essential services for niri session
echo "Enabling cosmic-notifications service..."
if [ -f "/usr/lib/systemd/user/cosmic-notifications.service" ]; then
    echo "cosmic-notifications.service found, configuring for niri session"
    # Add to niri session wants
    mkdir -p "/usr/lib/systemd/user/niri.service.wants"
    ln -sf "/usr/lib/systemd/user/cosmic-notifications.service" "/usr/lib/systemd/user/niri.service.wants/cosmic-notifications.service" || echo "cosmic-notifications.service already configured"
else
    echo "cosmic-notifications.service not found, skipping"
fi

echo "Checking for waybar service..."
if [ -f "/usr/lib/systemd/user/waybar.service" ]; then
    echo "waybar.service found, configuring for niri session"
    # Add to niri session wants
    mkdir -p "/usr/lib/systemd/user/niri.service.wants"
    ln -sf "/usr/lib/systemd/user/waybar.service" "/usr/lib/systemd/user/niri.service.wants/waybar.service" || echo "waybar.service already configured"
else
    echo "waybar.service not found, skipping"
fi

echo "Checking for cliphist service..."
if [ -f "/usr/lib/systemd/user/cliphist.service" ]; then
    echo "cliphist.service found, configuring for niri session"
    # Add to niri session wants
    mkdir -p "/usr/lib/systemd/user/niri.service.wants"
    ln -sf "/usr/lib/systemd/user/cliphist.service" "/usr/lib/systemd/user/niri.service.wants/cliphist.service" || echo "cliphist.service already configured"
else
    echo "cliphist.service not found, skipping"
fi

echo "Disabling cosmic-idle service (incompatible with current cosmic-settings-daemon)..."
if [ -f "/usr/lib/systemd/user/cosmic-idle.service" ]; then
    echo "cosmic-idle.service found, disabling for niri session"
    # Remove from graphical-session target wants
    rm -f "/etc/systemd/user/graphical-session.target.wants/cosmic-idle.service" || echo "cosmic-idle.service already removed from wants"
    # Mask the service
    mkdir -p "/etc/systemd/user"
    ln -sf "/dev/null" "/etc/systemd/user/cosmic-idle.service" || echo "cosmic-idle.service already masked"
else
    echo "cosmic-idle.service not found, skipping"
fi

echo "::endgroup::"

echo "Niri session services and portals configured successfully!"