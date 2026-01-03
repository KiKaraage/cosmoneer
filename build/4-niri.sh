#!/usr/bin/bash
set -eoux pipefail

echo "===$(basename "$0")==="
echo "::group:: Install Niri Window Manager"

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

copr_install_isolated "trixieua/morewaita-icon-theme" "morewaita-icon-theme"
copr_install_isolated "thrnciar/setuptools-78.1.1" "slurp"

# Install Niri from yalter/niri-git COPR directly
copr_install_isolated "yalter/niri-git" "niri" "priority"

# Configure Niri session to use COSMIC integration
cat > /usr/share/wayland-sessions/niri.desktop << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/bin/start-cosmic-ext-niri
Type=Application
DesktopNames=niri
EOF

echo "Niri window manager installed successfully"

echo "::endgroup::"
