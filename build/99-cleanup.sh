#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Cleanup GNOME and Silverblue Packages
###############################################################################
# This script removes GNOME/Silverblue packages that are not needed in base-main
###############################################################################

echo "::group:: Clean Up Package Cache"

echo "::group:: Clean Up Package Cache"

echo "Cleaning up package cache..."
dnf5 clean all

echo "Package cache cleaned"
echo "::endgroup::"

echo "Cleanup of GNOME and Silverblue packages complete!"