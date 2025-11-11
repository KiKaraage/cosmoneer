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
    switcheroo-control

echo "Installing printer drivers..."
dnf5 install -y \
    foo2zjs

echo "Installing mobile device support..."
dnf5 install -y \
    ifuse

echo "Installing networking tools..."
dnf5 install -y \
    tailscale \
    iwd \
    waypipe

echo "Installing additional utilities..."
dnf5 install -y \
    msedit \
    fontawesome-fonts \
    fontawesome-fonts-web

echo "Enabling Tailscale service..."
systemctl enable tailscaled

echo "::endgroup::"





echo "::group:: Installing Qt6 Theme Configuration"
# Install qt6ct from Fedora repos
echo "Checking qt6ct availability..."
QT6CT_VERSION=$(dnf5 info qt6ct | grep -E "^Version[[:space:]]*:" | awk '{print $3}')
echo "qt6ct version: $QT6CT_VERSION"
echo "Installing qt6ct for Qt6 application theming..."
dnf5 install -y qt6ct
echo "qt6ct installed successfully"
echo "::endgroup::"

echo "::group:: Configuring Qt6 Platform Theme"
# Add QT_QPA_PLATFORMTHEME to environment
echo "Setting QT_QPA_PLATFORMTHEME=qt6ct in /etc/environment..."
echo "QT_QPA_PLATFORMTHEME=qt6ct" >> /etc/environment
echo "Qt6 platform theme configured - Qt6 applications will now use qt6ct for theming"
echo "::endgroup::"

echo "Additional software installation complete!"