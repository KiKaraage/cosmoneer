#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Cleanup GNOME and Silverblue Packages
###############################################################################
# This script removes GNOME/Silverblue packages that are not needed in base-main
###############################################################################

echo "::group:: Remove GNOME Software Packages"

echo "Removing GNOME software packages..."
dnf5 remove -y \
    gnome-software \
    gnome-software-rpm-ostree \
    firefox \
    firefox-langpacks \
    podman-docker \
    yelp || true

echo "GNOME software packages removed"
echo "::endgroup::"

echo "::group:: Remove GNOME Integration Packages"

echo "Removing GNOME integration packages..."
dnf5 remove -y \
    totem-video-thumbnailer \
    gnome-terminal-nautilus \
    fedora-bookmarks \
    fedora-chromium-config \
    fedora-chromium-config-gnome \
    gnome-extension-app \
    gnome-shell-extension-background-logo || true

echo "GNOME integration packages removed"
echo "::endgroup::"

echo "::group:: Clean Up Package Cache"

echo "Cleaning up package cache..."
dnf5 clean all

echo "Package cache cleaned"
echo "::endgroup::"

echo "Cleanup of GNOME and Silverblue packages complete!"