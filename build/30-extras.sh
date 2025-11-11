#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Additional Software and External RPMs
###############################################################################
# This script installs additional software from dnf5 and external RPM sources
###############################################################################

echo "::group:: Install Hardware and Networking Packages"

dnf5 install -y \
    igt-gpu-tools \
    switcheroo-control \
    foo2zjs \
    ifuse \
    tailscale \
    iwd \
    waypipe \
    msedit \
    fontawesome-fonts \
    fontawesome-fonts-web

systemctl enable tailscaled

echo "::endgroup::"

echo "::group:: Configure Qt6 Theme"

dnf5 install -y qt6ct
echo "QT_QPA_PLATFORMTHEME=qt6ct" >> /etc/environment

echo "::endgroup::"