#!/bin/bash

# Combined portal setup and compositor detection script
# Usage: setup-portals.sh [desktop_name]
# If desktop_name is provided, skips detection and uses it

set -euo pipefail

# Robust Wayland compositor detection
detect_compositor() {
    # Method 1: Check running processes (most reliable after compositor startup)
    if pgrep -f "cosmic-comp" > /dev/null 2>&1; then
        echo "COSMIC"
        return 0
    fi
    
    if pgrep -f "niri" > /dev/null 2>&1; then
        echo "Niri"
        return 0
    fi
    
    # Method 2: Check session from loginctl (may not be available immediately)
    SESSION_ID=$(loginctl user-status | head -1 | awk '{print $1}')
    if [ -n "$SESSION_ID" ]; then
        SESSION_DESKTOP=$(loginctl show-session "$SESSION_ID" -p Desktop 2>/dev/null | cut -d= -f2)
        case "$SESSION_DESKTOP" in
            "COSMIC")
                echo "COSMIC"
                return 0
                ;;
            "Niri")
                echo "Niri"
                return 0
                ;;
        esac
    fi
    
    # Method 3: Fallback to environment variables
    echo "${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-Niri}}"
}

# Main setup function
setup_portals() {
    local desktop="$1"
    echo "Setting up portals for desktop: $desktop"
    
    local portal_config_dir="/usr/share/xdg-desktop-portal"
    local user_config="/run/user/$(id -u)/xdg-desktop-portal.conf"
    
    case "$desktop" in
        "COSMIC")
            echo "Using COSMIC portal configuration"
            if [ -f "$portal_config_dir/cosmic-portals.conf" ]; then
                cp "$portal_config_dir/cosmic-portals.conf" "$user_config"
            fi
            # Enable COSMIC portal service
            systemctl --user enable xdg-desktop-portal-cosmic.service 2>/dev/null || true
            systemctl --user disable xdg-desktop-portal-gnome.service 2>/dev/null || true
            ;;
        "Niri")
            echo "Using Niri (GNOME) portal configuration"
            if [ -f "$portal_config_dir/niri-portals.conf" ]; then
                cp "$portal_config_dir/niri-portals.conf" "$user_config"
            fi
            # Enable GNOME portal service
            systemctl --user enable xdg-desktop-portal-gnome.service 2>/dev/null || true
            systemctl --user disable xdg-desktop-portal-cosmic.service 2>/dev/null || true
            ;;
        *)
            echo "Unknown desktop '$desktop', using default GNOME configuration"
            if [ -f "$portal_config_dir/niri-portals.conf" ]; then
                cp "$portal_config_dir/niri-portals.conf" "$user_config"
            fi
            systemctl --user enable xdg-desktop-portal-gnome.service 2>/dev/null || true
            systemctl --user disable xdg-desktop-portal-cosmic.service 2>/dev/null || true
            ;;
    esac
    
    # Restart main portal service
    systemctl --user restart xdg-desktop-portal.service 2>/dev/null || true
    echo "Portal setup completed"
}

# Main execution
main() {
    local desktop
    
    if [ $# -eq 1 ]; then
        desktop="$1"
        echo "Using provided desktop: $desktop"
    else
        desktop=$(detect_compositor)
        echo "Detected desktop: $desktop"
    fi
    
    setup_portals "$desktop"
}

# Run main function with all arguments
main "$@"