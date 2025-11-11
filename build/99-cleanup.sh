#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Cleanup GNOME and Silverblue Packages
###############################################################################
# This script removes GNOME/Silverblue packages that are not needed in base-main
###############################################################################

echo "::group:: Clean Up Package Cache"

dnf5 clean all

echo "::endgroup::"