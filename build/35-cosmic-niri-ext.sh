#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Build and Install cosmic-ext-alternative-startup for Niri
###############################################################################
# This script builds cosmic-ext-alternative-startup from source and installs
# the necessary files to enable COSMIC apps in Niri.
#
# Based on: https://github.com/Drakulix/cosmic-ext-extra-sessions/tree/main/niri
###############################################################################

echo "::group:: Install cosmic-ext-alternative-startup Dependencies"

# Install Rust and cargo if not already present
dnf5 install -y \
    cargo \
    rust \
    libxkbcommon-devel \
    wayland-devel

echo "Build dependencies installed"
echo "::endgroup::"

echo "::group:: Build cosmic-ext-alternative-startup"

# Clone and build cosmic-ext-alternative-startup
cd /tmp
git clone --depth 1 https://github.com/Drakulix/cosmic-ext-alternative-startup.git
cd cosmic-ext-alternative-startup

# Build the project
export CARGO_HOME="/tmp/cargo"
export CARGO_TARGET_DIR="/tmp/cargo-target"
mkdir -p "$CARGO_HOME" "$CARGO_TARGET_DIR"
cargo build --release

# Install the binary
install -Dm755 "$CARGO_TARGET_DIR/release/cosmic-ext-alternative-startup" /usr/bin/cosmic-ext-alternative-startup

echo "cosmic-ext-alternative-startup built and installed"
echo "::endgroup::"

echo "::group:: Clone Niri Session Files"

# Clone the cosmic-ext-extra-sessions repo for Niri configuration
cd /tmp
git clone --depth 1 https://github.com/Drakulix/cosmic-ext-extra-sessions.git
cd cosmic-ext-extra-sessions/niri

# Install start-cosmic-ext-niri script
install -Dm755 start-cosmic-ext-niri /usr/bin/start-cosmic-ext-niri

# Update session file to use installed path
sed -i 's|/usr/local/bin/start-cosmic-ext-niri|/usr/bin/start-cosmic-ext-niri|' cosmic-ext-niri.desktop

# Install cosmic-ext-niri.desktop session file
install -Dm644 cosmic-ext-niri.desktop /usr/share/wayland-sessions/cosmic-ext-niri.desktop

echo "Niri session files installed"
echo "::endgroup::"

echo "::group:: Cleanup"

# Clean up build artifacts
cd /
rm -rf /tmp/cosmic-ext-alternative-startup /tmp/cosmic-ext-extra-sessions

echo "Cleanup complete"
echo "::endgroup::"

echo "cosmic-ext-alternative-startup installation complete!"
