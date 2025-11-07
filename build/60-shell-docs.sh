#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Shell Enhancements and Documentation
###############################################################################
# This script installs shell enhancements and project documentation
###############################################################################

echo "::group:: Install Shell Enhancements"

echo "Installing Starship shell prompt..."
# Download and install Starship
curl -L "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin/starship

# Add Starship to bashrc
echo "eval \"\$(starship init bash)\"" >> /etc/bashrc

echo "Cleaning up boot messages..."
# Remove console-login-helper-messages for cleaner boot
dnf5 remove -y console-login-helper-messages || true

echo "::endgroup::"

echo "::group:: Install Project Documentation"

echo "Installing Cosmoneer documentation..."
# Create documentation directory
mkdir -p /usr/share/doc/cosmoneer

# Add basic Cosmoneer documentation
cat > /usr/share/doc/cosmoneer/README.md << 'EOF'
# Cosmoneer

A scroller desktop OS with COSMIC + Niri + ublue polish.

## Getting Started

1. **First Login**: Log into "cosmic" session for full COSMIC desktop
2. **Niri + COSMIC**: Log into "cosmic-ext-niri" session for Niri with COSMIC apps
3. **Configure**: Run `ujust configure-niri-cosmic` if needed

## Key Features

- **COSMIC Desktop**: Modern Rust-based desktop environment
- **Niri WM**: Scrollable tiling Wayland compositor  
- **ublue Integration**: Hardware support, auto-updates, polish
- **Docker CE**: Container runtime with compose plugin
- **Homebrew**: Package manager via ublue-brew

## ujust Commands

- `ujust configure-niri-cosmic` - Set up Niri for COSMIC
- `ujust install-default-apps` - Install CLI tools via Homebrew
- `ujust configure-dev-groups` - Add user to docker/libvirt groups

## Session Types

- **cosmic**: Full COSMIC desktop environment
- **cosmic-ext-niri**: Niri WM with COSMIC app integration

*Last updated: $(date +%Y-%m-%d)*
EOF

echo "::endgroup::"

echo "Shell enhancements and documentation installation complete!"