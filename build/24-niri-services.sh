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
    if systemctl list-unit-files | grep -q "^${service}$"; then
        systemctl --global enable "$service" || echo "$service already enabled globally"
    else
        echo "$service not found, skipping"
    fi
done

echo "::endgroup::"

echo "::group:: Configure Niri Session Services"

# Enable essential services for niri session
echo "Enabling cosmic-notifications service..."
if systemctl --user list-unit-files | grep -q "cosmic-notifications.service$"; then
    # Check if already enabled by preset
    if ! systemctl --user is-enabled cosmic-notifications.service >/dev/null 2>&1; then
        systemctl --user enable cosmic-notifications.service
        echo "cosmic-notifications.service enabled"
    else
        echo "cosmic-notifications.service already enabled"
    fi
    # Add to niri session wants
    systemctl --user add-wants niri.service cosmic-notifications.service || echo "cosmic-notifications.service already configured"
else
    echo "cosmic-notifications.service not found, skipping"
fi

echo "Checking for waybar service..."
if systemctl --user list-unit-files | grep -q "waybar.service$"; then
    # Check if already enabled by preset
    if ! systemctl --user is-enabled waybar.service >/dev/null 2>&1; then
        systemctl --user enable waybar.service
        echo "waybar.service enabled"
    else
        echo "waybar.service already enabled"
    fi
    # Add to niri session wants
    systemctl --user add-wants niri.service waybar.service || echo "waybar.service already configured"
else
    echo "waybar.service not found, skipping"
fi

echo "Checking for cliphist service..."
if systemctl --user list-unit-files | grep -q "cliphist.service$"; then
    # Check if already enabled by preset
    if ! systemctl --user is-enabled cliphist.service >/dev/null 2>&1; then
        systemctl --user enable cliphist.service
        echo "cliphist.service enabled"
    else
        echo "cliphist.service already enabled"
    fi
    # Add to niri session wants
    systemctl --user add-wants niri.service cliphist.service || echo "cliphist.service already configured"
else
    echo "cliphist.service not found, skipping"
fi

echo "Disabling cosmic-idle service (incompatible with current cosmic-settings-daemon)..."
if systemctl --user list-unit-files | grep -q "cosmic-idle.service$"; then
    # Check if already disabled/masked
    if systemctl --user is-enabled cosmic-idle.service >/dev/null 2>&1; then
        systemctl --user disable cosmic-idle.service
        echo "cosmic-idle.service disabled"
    else
        echo "cosmic-idle.service already disabled"
    fi
    systemctl --user mask cosmic-idle.service || echo "cosmic-idle.service already masked"
else
    echo "cosmic-idle.service not found, skipping"
fi

echo "::endgroup::"

echo "Niri session services and portals configured successfully!"