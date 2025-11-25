# vim: set ft=make :
#####################
### custom-niri.just
#####################
## Commands for configuring Niri with COSMIC

# Configure Niri for COSMIC integration (minimal additive approach)
[group('System')]
configure-niri-cosmic:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh

    CONFIG_DIR="$HOME/.config/niri"
    CONFIG_FILE="$CONFIG_DIR/config.kdl"

    echo "Configuring Niri for COSMIC integration..."

    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # Handle existing vs new configs
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Setting up default Niri configuration with COSMIC integration..."
        cp /etc/skel/.config/niri/config.kdl "$CONFIG_FILE"
        echo "Default configuration applied!"
    else
        echo "Existing Niri configuration found."

        echo "Existing Niri configuration will work with COSMIC via cosmic-session."

        echo "Keeping your existing Niri keybindings."
        echo "Use 'ujust show-niri-config' to view current configuration."
    fi

    echo "COSMIC integration is ready!"
    echo "Log out and log back in to the COSMIC (Niri) session for changes to take effect."

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
