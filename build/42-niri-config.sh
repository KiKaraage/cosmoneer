#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Auto-Configure Niri for COSMIC Integration
###############################################################################
# This script automatically configures Niri for COSMIC integration
# so users can use "COSMIC in Niri" session right away
###############################################################################

echo "::group:: Auto-Configure Niri for COSMIC"

# Create default Niri config directory and file
echo "Creating default Niri configuration..."
mkdir -p /etc/skel/.config/niri

# Create a basic Niri config with COSMIC integration
cat > /etc/skel/.config/niri/config.kdl << 'NIRI_CONFIG'
// Niri configuration with COSMIC integration
// Generated automatically during Cosmoneer build

input {
    keyboard {
        xkb {
            layout "us"
        }
    }
    touchpad {
        tap
        natural-scroll
    }
}

output {
    // Auto-configure displays
}

// Launch COSMIC services at startup
spawn-at-startup "cosmic-ext-alternative-startup"

// COSMIC Integration Keybindings
binds {
    Mod+T { spawn "cosmic-term"; }
    Mod+D { spawn "cosmic-launcher"; }
    Mod+Shift+D { spawn "cosmic-app-library"; }
    Mod+Alt+L { spawn "cosmic-greeter"; }
}

// Default workspace layout
layout {
    gaps 8
    default-tab-width 200
}

// Window rules
window-rule {
    match app-id="cosmic-term"
    open-floating true
}

window-rule {
    match app-id="cosmic-launcher"
    open-floating true
    center true
    width 800
    height 600
}
NIRI_CONFIG

echo "Default Niri configuration created with COSMIC integration"
echo "::endgroup::"

echo "Niri auto-configuration complete!"
echo "Users can now log into 'cosmic-ext-niri' session immediately."