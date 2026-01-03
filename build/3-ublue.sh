#!/usr/bin/bash
set -eoux pipefail

echo "===$(basename "$0")==="
echo "::group:: Universal Blue Services Setup"

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "Installing packages from COPR ublue-os/packages"
copr_install_isolated "ublue-os/packages" \
    "ublue-os-udev-rules" \
    "uupd"

echo "::group:: Configure Universal Blue Integration"

# Configure uupd to disable distrobox module
if [ -f "/usr/lib/systemd/system/uupd.service" ]; then
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
    echo "uupd configured to disable distrobox module"
fi

# Enable COPR-installed services
systemctl enable uupd.timer || echo "uupd.timer already enabled or not found"

echo "::endgroup::"

echo "::endgroup::"

echo "::endgroup::"
