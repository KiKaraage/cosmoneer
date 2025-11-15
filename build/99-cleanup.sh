#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Cleanup GNOME and Silverblue Packages
###############################################################################
# This script removes GNOME/Silverblue packages that are not needed in base-main
###############################################################################

echo "::group:: Clean Up Package Cache"

# Clean package caches aggressively
dnf5 clean all
rm -rf /var/cache/dnf/* /var/cache/yum/* 2>/dev/null || true

# Remove temporary files and logs
rm -rf /var/tmp/* /tmp/* /var/log/* /var/log/journal/* 2>/dev/null || true

# Remove documentation and man pages to save space
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* 2>/dev/null || true
# Clean up any remaining cache files
find /var/cache -type f -delete 2>/dev/null || true
find /tmp -type f -delete 2>/dev/null || true

# Remove development files that might be left over
find /usr -name "*.a" -delete 2>/dev/null || true
find /usr -name "*.la" -delete 2>/dev/null || true
echo "::endgroup::"