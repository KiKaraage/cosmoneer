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

echo "::group:: Enable GNOME Keyring Services"

# Create user preset to enable GNOME Keyring for all users
mkdir -p /etc/systemd/user-preset.d
cat > /etc/systemd/user-preset.d/00-gnome-keyring.preset << 'EOF'
[Install]
gnome-keyring-daemon.socket=yes
gnome-keyring-daemon.service=yes
EOF

# Enable GNOME Keyring services system-wide for all users
systemctl --global enable gnome-keyring-daemon.socket || echo "Failed to globally enable gnome-keyring-daemon.socket"
systemctl --global enable gnome-keyring-daemon.service || echo "Failed to globally enable gnome-keyring-daemon.service"

# Configure PAM for gnome-keyring integration with cosmic-greeter
if [ -f "/etc/pam.d/cosmic-greeter" ]; then
    echo "PAM configuration for cosmic-greeter found"
else
    echo "Warning: cosmic-greeter PAM configuration not found"
fi

echo "GNOME Keyring services enabled globally"
echo "::endgroup::"

echo "::group:: Install cosmic-ext-bg-theme"

# Check if binary exists in applets artifacts
if [ -d "/applets/cosmic-ext-bg-theme" ]; then
    # Look for the binary in the directory
    BINARY_PATH=""
    if [ -f "/applets/cosmic-ext-bg-theme/cosmic-ext-bg-theme" ]; then
        BINARY_PATH="/applets/cosmic-ext-bg-theme/cosmic-ext-bg-theme"
    else
        # Find any executable binary in the directory
        BINARY_PATH=$(find "/applets/cosmic-ext-bg-theme" -name "cosmic-ext-bg-theme" -type f -executable | head -1)
    fi

    if [ -n "$BINARY_PATH" ]; then
        echo "Found cosmic-ext-bg-theme binary in artifacts, installing..."
        install -Dm755 "$BINARY_PATH" /usr/bin/cosmic-ext-bg-theme
        echo "cosmic-ext-bg-theme installed from artifacts: $BINARY_PATH"

        # Install desktop file if present
        if [ -f "/applets/cosmic-ext-bg-theme/res/cosmic.ext.BgTheme.desktop" ]; then
            install -Dm644 "/applets/cosmic-ext-bg-theme/res/cosmic.ext.BgTheme.desktop" /usr/share/applications/cosmic.ext.BgTheme.desktop
            echo "Installed desktop file: cosmic.ext.BgTheme.desktop"
        elif [ -f "/applets/cosmic-ext-bg-theme/cosmic.ext.BgTheme.desktop" ]; then
            install -Dm644 "/applets/cosmic-ext-bg-theme/cosmic.ext.BgTheme.desktop" /usr/share/applications/cosmic.ext.BgTheme.desktop
            echo "Installed desktop file: cosmic.ext.BgTheme.desktop"
        fi
    else
        echo "cosmic-ext-bg-theme binary not found in artifacts directory, building from source..."
        BUILD_BG_THEME=true
    fi
elif [ -f "/applets/cosmic-ext-bg-theme" ]; then
    echo "Found cosmic-ext-bg-theme binary as file in artifacts, installing..."
    install -Dm755 /applets/cosmic-ext-bg-theme /usr/bin/cosmic-ext-bg-theme
    echo "cosmic-ext-bg-theme installed from artifacts"
else
    echo "cosmic-ext-bg-theme binary not found in artifacts, building from source..."
    BUILD_BG_THEME=true
fi

if [ "${BUILD_BG_THEME:-false}" = "true" ]; then
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

echo "::group:: Add COSMIC Flatpak Remote"

# Add COSMIC Flatpak remote for applets in COSMIC Store
flatpak remote-add --if-not-exists --system cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo

echo "COSMIC Flatpak remote configured"
echo "::endgroup::"

# Clean up build artifacts
cd /
rm -rf /tmp/cosmic-ext-extra-sessions

echo "Cleanup complete"
echo "COSMIC desktop and Niri installation complete!"
