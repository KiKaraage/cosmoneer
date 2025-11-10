#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# COSMIC Desktop and Niri Window Manager
###############################################################################
# This script combines the installation of COSMIC desktop and Niri window manager
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh



echo "::group:: Install COSMIC Desktop"

# Install COSMIC desktop from System76's COPR
# Using isolated pattern to prevent COPR from persisting
copr_install_isolated "ryanabx/cosmic-epoch" \
    cosmic-app-library \
    cosmic-applets \
    cosmic-bg \
    cosmic-comp \
    cosmic-edit \
    cosmic-files \
    cosmic-greeter \
    cosmic-icon-theme \
    cosmic-idle \
    cosmic-initial-setup \
    cosmic-launcher \
    cosmic-notifications \
    cosmic-osd \
    cosmic-panel \
    cosmic-player \
    cosmic-randr \
    cosmic-screenshot \
    cosmic-session \
    cosmic-settings \
    cosmic-settings-daemon \
    cosmic-store \
    cosmic-term \
    cosmic-wallpapers \
    cosmic-workspaces \
    pop-launcher \
    xdg-desktop-portal-cosmic

echo "COSMIC desktop installed successfully"
echo "::endgroup::"

echo "::group:: Install Niri Window Manager"

# Install Niri from yalter/niri-git COPR
copr_install_isolated "yalter/niri-git" niri

echo "Niri window manager installed successfully"
echo "::endgroup::"

echo "::group:: Configure Display Manager"

# Enable cosmic-greeter (COSMIC's display manager)
systemctl enable cosmic-greeter

# Set COSMIC as default session
mkdir -p /etc/X11/sessions
cat > /etc/X11/sessions/cosmic.desktop << 'COSMICDESKTOP'
[Desktop Entry]
Name=COSMIC
Comment=COSMIC Desktop Environment
Exec=cosmic-session
Type=Application
DesktopNames=COSMIC
COSMICDESKTOP

echo "Display manager configured"
echo "::endgroup::"

echo "::group:: Install cosmic-ext-alternative-startup for Niri"

# Check if binary exists in applets artifacts
if [ -f "/applets/cosmic-ext-alternative-startup" ]; then
    echo "Found cosmic-ext-alternative-startup binary in artifacts, installing..."
    install -Dm755 /applets/cosmic-ext-alternative-startup /usr/bin/cosmic-ext-alternative-startup
    echo "cosmic-ext-alternative-startup installed from artifacts"
else
    echo "cosmic-ext-alternative-startup binary not found in artifacts, building from source..."
    
    # Install dependencies for building
    dnf5 install -y \
        cargo \
        rust \
        libxkbcommon-devel \
        wayland-devel

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
    
    # Cleanup build artifacts
    cd /
    rm -rf /tmp/cosmic-ext-alternative-startup /tmp/cargo /tmp/cargo-target
fi

echo "::endgroup::"

echo "::group:: Install cosmic-ext-bg-theme"

# Check if binary exists in applets artifacts
if [ -f "/applets/cosmic-ext-bg-theme" ]; then
    echo "Found cosmic-ext-bg-theme binary in artifacts, installing..."
    install -Dm755 /applets/cosmic-ext-bg-theme /usr/bin/cosmic-ext-bg-theme
    echo "cosmic-ext-bg-theme installed from artifacts"
else
    echo "cosmic-ext-bg-theme binary not found in artifacts, building from source..."
    
    # Install dependencies for building
    dnf5 install -y \
        cargo \
        rust \
        libxkbcommon-devel \
        wayland-devel

    # Clone and build cosmic-ext-bg-theme
    cd /tmp
    git clone --depth 1 https://github.com/wash2/cosmic_ext_bg_theme.git
    cd cosmic_ext_bg_theme

    # Build the project
    export CARGO_HOME="/tmp/cargo"
    export CARGO_TARGET_DIR="/tmp/cargo-target"
    mkdir -p "$CARGO_HOME" "$CARGO_TARGET_DIR"
    cargo build --release

    # Install the binary
    install -Dm755 "$CARGO_TARGET_DIR/release/cosmic-ext-bg-theme" /usr/bin/cosmic-ext-bg-theme

    # Install desktop file
    install -Dm644 res/cosmic.ext.BgTheme.desktop /usr/share/applications/cosmic.ext.BgTheme.desktop

    echo "cosmic-ext-bg-theme built and installed"
    
    # Cleanup build artifacts
    cd /
    rm -rf /tmp/cosmic_ext_bg_theme /tmp/cargo /tmp/cargo-target
fi

echo "::endgroup::"

echo "::group:: Install Niri Session Files"

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

echo "::group:: Add COSMIC Flatpak Remote"

# Add COSMIC Flatpak remote
flatpak remote-add --if-not-exists --system cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo

echo "COSMIC Flatpak remote configured"
echo "::endgroup::"

echo "::group:: Cleanup"

# Clean up build artifacts
cd /
rm -rf /tmp/cosmic-ext-extra-sessions

echo "Cleanup complete"
echo "::endgroup::"

echo "COSMIC desktop and Niri installation complete!"