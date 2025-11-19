#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Additional Software and External RPMs
###############################################################################
# This script installs additional software from dnf5 and external RPM sources
###############################################################################

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

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
    fontawesome-fonts-web \
    adwaita-icon-theme

systemctl enable tailscaled

echo "::endgroup::"

copr_install_isolated "trixieua/morewaita-icon-theme" "morewaita-icon-theme"

