#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Build and Install COSMIC Applets from Source
###############################################################################
# This script builds various COSMIC applets that don't have Flatpak support
# and installs them into the system.
#
# Applets installed:
# - cosmic-ext-applet-emoji-selector
# - cosmic-ext-applet-privacy-indicator
# - cosmic-ext-applet-vitals
# - cosmic-applet-music-player
# - cosmic-ext-applet-caffeine
# - cosmic-connect-applet
###############################################################################

echo "::group:: Install Build Dependencies"

# Install all build dependencies needed for COSMIC applets
# Many of these may already be installed from previous build steps
dnf5 install -y --skip-unavailable \
    just \
    cargo \
    rust \
    git \
    gcc \
    gcc-c++ \
    make \
    libxkbcommon-devel \
    pipewire-devel \
    dbus-devel \
    openssl-devel \
    pkgconf-pkg-config \
    wayland-devel

echo "Build dependencies installed"
echo "::endgroup::"

# Set up cargo environment
export CARGO_HOME="/tmp/cargo"
export CARGO_TARGET_DIR="/tmp/cargo-target"
export JUST_COLOR=never
mkdir -p "$CARGO_HOME" "$CARGO_TARGET_DIR"

# Helper function for building and installing applets using Just
build_and_install_applet() {
    local repo_name="$1"
    local repo_url="$2"
    local repo_dir="/tmp/${repo_name}"

    rm -rf "${repo_dir}"
    git clone --depth 1 "${repo_url}" "${repo_dir}"

    pushd "${repo_dir}" >/dev/null

    if just --list 2>/dev/null | grep -q "build-release"; then
        just build-release
    else
        cargo build --release
    fi

    just install

    popd >/dev/null
}

echo "::group:: Build cosmic-ext-applet-emoji-selector"
build_and_install_applet "cosmic-ext-applet-emoji-selector" "https://github.com/leb-kuchen/cosmic-ext-applet-emoji-selector"
echo "cosmic-ext-applet-emoji-selector installed"
echo "::endgroup::"

echo "::group:: Build cosmic-ext-applet-privacy-indicator"
build_and_install_applet "cosmic-ext-applet-privacy-indicator" "https://github.com/D-Brox/cosmic-ext-applet-privacy-indicator"
echo "cosmic-ext-applet-privacy-indicator installed"
echo "::endgroup::"

echo "::group:: Build cosmic-ext-applet-vitals"
build_and_install_applet "cosmic-ext-applet-vitals" "https://github.com/Coinio/cosmic-ext-applet-vitals.git"
echo "cosmic-ext-applet-vitals installed"
echo "::endgroup::"

echo "::group:: Build cosmic-applet-music-player"
build_and_install_applet "cosmic-applet-music-player" "https://github.com/Ebbo/cosmic-applet-music-player.git"
echo "cosmic-applet-music-player installed"
echo "::endgroup::"

echo "::group:: Build cosmic-ext-applet-caffeine"
build_and_install_applet "cosmic-ext-applet-caffeine" "https://github.com/tropicbliss/cosmic-ext-applet-caffeine"
echo "cosmic-ext-applet-caffeine installed"
echo "::endgroup::"

echo "::group:: Build cosmic-connect-applet"
build_and_install_applet "cosmic-connect-applet" "https://github.com/cosmic-utils/cosmic-connect-applet.git"
echo "cosmic-connect-applet installed"
echo "::endgroup::"

echo "::group:: Cleanup"
cd /
rm -rf /tmp/cosmic-ext-applet-emoji-selector
rm -rf /tmp/cosmic-ext-applet-privacy-indicator
rm -rf /tmp/cosmic-ext-applet-vitals
rm -rf /tmp/cosmic-applet-music-player
rm -rf /tmp/cosmic-ext-applet-caffeine
rm -rf /tmp/cosmic-connect-applet
rm -rf "$CARGO_HOME" "$CARGO_TARGET_DIR"

echo "Cleanup complete"
echo "::endgroup::"

echo "All COSMIC applets installed successfully!"
