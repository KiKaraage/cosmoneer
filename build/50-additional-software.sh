#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Additional Software and External RPMs
###############################################################################
# This script installs additional software from dnf5 and external RPM sources
###############################################################################

echo "::group:: Install Hardware and Networking Packages"

echo "Installing hardware support packages..."
dnf5 install -y \
    igt-gpu-tools \
    libratbag-ratbagd \
    switcheroo-control

echo "Installing printer drivers..."
dnf5 install -y \
    printer-driver-brlaser \
    foo2zjs \
    hplip

echo "Installing mobile device support..."
dnf5 install -y \
    libimobiledevice \
    ifuse \
    usbmuxd

echo "Installing networking tools..."
dnf5 install -y \
    wireguard-tools \
    tailscale \
    iwd \
    waypipe \
    wl-clipboard \
    krb5-workstation

echo "Enabling Tailscale service..."
systemctl enable tailscaled

echo "::endgroup::"

echo "::group:: Install GitHub Release RPMs"

# This section can be used to install RPMs from GitHub releases
# Example usage (uncomment and modify as needed):
#
# echo "Installing tool from GitHub release..."
# curl -L -o /tmp/tool.rpm "https://github.com/user/repo/releases/download/v1.0.0/tool.rpm"
# dnf5 install -y /tmp/tool.rpm
# rm -f /tmp/tool.rpm

echo "No GitHub release RPMs configured"
echo "::endgroup::"

# COSMIC Applets are now handled in 41-cosmic-applets.sh

echo "Additional software installation complete!"