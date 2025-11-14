#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Cleanup GNOME and Silverblue Packages
###############################################################################
# This script removes GNOME/Silverblue packages that are not needed in base-main
###############################################################################

echo "::group:: Clean Up Package Cache"

dnf5 clean all

# Additional cleanup to reduce image size
rm -rf /var/tmp/* /tmp/* /var/log/* 2>/dev/null || true
rm -rf /usr/share/doc/* /usr/share/man/* 2>/dev/null || true
find /var/cache -type f -delete 2>/dev/null || true

echo "::endgroup::"