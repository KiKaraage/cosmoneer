# vim: set ft=make :
#####################
### custom-niri.just
#####################
## Commands for configuring Niri with COSMIC

# Configure Niri for COSMIC integration
[group('System')]
configure-niri-cosmic:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    
    CONFIG_DIR="$HOME/.config/niri"
    CONFIG_FILE="$CONFIG_DIR/config.kdl"
    
    echo "Configuring Niri for COSMIC integration..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Run niri once to generate default config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Generating default Niri configuration..."
        # Note: This might need to be run in a different way depending on environment
        echo "Please run 'niri' once to generate a default config, then run this command again."
        exit 1
    fi
    
    # Backup existing config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backed up existing config"
    
    # Check if spawn-at-startup is already configured
    if grep -q "spawn-at-startup.*cosmic-ext-alternative-startup" "$CONFIG_FILE"; then
        echo "COSMIC spawn-at-startup already configured"
    else
        echo "Adding COSMIC spawn-at-startup to Niri config..."
        # Add spawn-at-startup for COSMIC
        echo '' >> "$CONFIG_FILE"
        echo 'spawn-at-startup "cosmic-ext-alternative-startup"' >> "$CONFIG_FILE"
    fi
    
    # Check if COSMIC keybindings are already configured
    if grep -q "cosmic-term" "$CONFIG_FILE"; then
        echo "COSMIC keybindings already configured"
    else
        echo "Adding COSMIC keybindings to Niri config..."
        # Add COSMIC keybindings
        cat >> "$CONFIG_FILE" << 'EOF'

// COSMIC Integration Keybindings
binds {
    Mod+T { spawn "cosmic-term"; }
    Mod+D { spawn "cosmic-launcher"; }
    Mod+Shift+D { spawn "cosmic-app-library"; }
    Mod+Alt+L { spawn "cosmic-greeter"; }
}
EOF
    fi
    
    echo "Niri configuration for COSMIC complete!"
    echo "Log out and log back into the COSMIC-Niri session for changes to take effect."

# Show current Niri configuration
[group('System')]
show-niri-config:
    #!/usr/bin/bash
    CONFIG_FILE="$HOME/.config/niri/config.kdl"
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "Niri config not found. Run niri once to generate it."
    fi

# Reset Niri configuration to defaults
[group('System')]
reset-niri-config:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CONFIG_DIR="$HOME/.config/niri"
    CONFIG_FILE="$CONFIG_DIR/config.kdl"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "No Niri config found to reset."
        exit 0
    fi
    
    if gum confirm "Reset Niri config to defaults? (A backup will be created)"; then
        # Backup current config
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
        rm "$CONFIG_FILE"
        echo "Config reset. Run niri once to generate a new default config."
        echo "Then run 'ujust configure-niri-cosmic' to reconfigure COSMIC integration."
    else
        echo "Config reset cancelled."
    fi
