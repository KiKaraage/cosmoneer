#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Install Additional Fonts
###############################################################################
# This script installs additional fonts for better desktop experience.
# Adapted from bluebuild fonts module (Apache-2.0 license)
# https://github.com/blue-build/modules/tree/main/modules/fonts
###############################################################################

echo "::group:: Install Additional Fonts"

# Install popular font packages from Fedora repos
dnf5 install -y \
    google-noto-emoji-fonts \
    google-noto-sans-fonts \
    google-noto-serif-fonts \
    google-noto-sans-mono-fonts \
    fira-code-fonts \
    mozilla-fira-mono-fonts \
    mozilla-fira-sans-fonts \
    jetbrains-mono-fonts-all \
    liberation-fonts \
    dejavu-fonts-all \
    fontawesome-fonts \
    fontawesome-fonts-web

echo "Additional fonts installed"
echo "::endgroup::"

echo "::group:: Update Font Cache"

# Update font cache
fc-cache -f

echo "Font cache updated"
echo "::endgroup::"

echo "Font installation complete!"
