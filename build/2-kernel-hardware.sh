#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Kernel and Hardware Support
###############################################################################
# This script handles kernel version locking and AKMODS for hardware support
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "===$(basename "$0")==="
echo "::group:: Kernel Version Management"

# Set kernel and akmods flavor from build args
AKMODS_FLAVOR="${AKMODS_FLAVOR:-main-43}"
KERNEL="${KERNEL:-}"

echo "Using AKMODS flavor: $AKMODS_FLAVOR"
echo "Target kernel version: $KERNEL"

if [ -n "$KERNEL" ]; then
    echo "Removing existing kernel packages..."
    rpm --erase --nodeps kernel kernel-core kernel-modules kernel-modules-extra || true

    echo "Installing kernel version: $KERNEL"
    dnf5 install -y "kernel-$KERNEL" "kernel-core-$KERNEL" "kernel-modules-$KERNEL" "kernel-modules-extra-$KERNEL"

    echo "Locking kernel version to prevent updates..."
    dnf5 versionlock add "kernel-$KERNEL" "kernel-core-$KERNEL" "kernel-modules-$KERNEL" "kernel-modules-extra-$KERNEL"
fi

echo "::endgroup::"

echo "::group:: AKMODS Hardware Support"

# Fetch AKMODS from container registry
echo "Fetching AKMODS from ghcr.io/ublue-os/akmods:$AKMODS_FLAVOR"
skopeo copy --remove-signatures "docker://ghcr.io/ublue-os/akmods:$AKMODS_FLAVOR" "oci-archive:/tmp/akmods.tar"

echo "Extracting AKMODS packages..."
mkdir -p /tmp/akmods-extracted
tar -xf /tmp/akmods.tar -C /tmp/akmods-extracted

# Find and install AKMODS RPMs
echo "Installing AKMODS packages..."
find /tmp/akmods-extracted -name "*.rpm" -exec dnf5 install -y {} \;

echo "::endgroup::"

echo "::group:: Hardware Module Installation"

# Enable ublue-os/akmods COPR temporarily
# echo "Temporarily enabling ublue-os/akmods COPR..."
# dnf5 -y copr enable ublue-os/akmods
# dnf5 -y copr disable ublue-os/akmods

# Install hardware-specific modules
# echo "Installing hardware support modules..."

# Gaming controllers (temporarily disabled due to build issues)
# copr_install_isolated "ublue-os/akmods" "akmod-xone"

# Razer devices (temporarily disabled due to build issues)
# copr_install_isolated "ublue-os/akmods" "akmod-openrazer"

# Framework laptop (temporarily disabled due to build issues)
# copr_install_isolated "ublue-os/akmods" "akmod-framework-laptop"

# Virtual camera (temporarily disabled due to build issues)
# copr_install_isolated "ublue-os/akmods" "akmod-v4l2loopback"

# echo "Hardware modules temporarily disabled to fix build issues"

echo "::endgroup::"

echo "::group:: Install Firmware Packages"

echo "Wireless firmware already installed, skipping..."

echo "Audio firmware already installed, skipping..."

echo "Installing camera firmware..."
dnf5 install -y --skip-unavailable \
    libcamera-v4l2

echo "Installing network and storage packages..."
dnf5 install -y --skip-unavailable \
    gvfs-smb \
    fuse-devel

echo "::endgroup::"

echo "Kernel and hardware support configuration complete!"
