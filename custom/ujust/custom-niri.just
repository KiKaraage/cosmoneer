# vim: set ft=make :
#####################
### custom-niri.just
#####################
## Commands for configuring Niri with COSMIC

# Install or update niri-window-buttons
[group('System')]
update-niriwaybar:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    
    echo "Installing/updating niri-window-buttons..."
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        echo "Error: gh CLI not found. Please install it first:"
        echo "  flatpak install flathub com.github.cli.cli"
        exit 1
    fi
    
    # Create waybar config directory if it doesn't exist
    mkdir -p "$HOME/.config/waybar"
    
    # Download the latest artifact
    LATEST_ARTIFACT_URL=$(gh run list --limit 1 --workflow "niri_window_buttons Update" --json artifacts --jq '.[0].artifacts[] | select(.name == "niri_window_buttons") | .archive_download_url' | head -1)
    
    if [ -n "$LATEST_ARTIFACT_URL" ]; then
        echo "Downloading latest niri-window-buttons..."
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        gh api "$LATEST_ARTIFACT_URL" > artifact.zip
        unzip artifact.zip
        
        if [ -f "libniri_window_buttons.so" ]; then
            # Backup existing version if present
            if [ -f "$HOME/.config/waybar/libniri_window_buttons.so" ]; then
                cp "$HOME/.config/waybar/libniri_window_buttons.so" "$HOME/.config/waybar/libniri_window_buttons.so.backup-$(date +%Y%m%d-%H%M%S)"
            fi
            
            # Install the new version
            install -Dm755 libniri_window_buttons.so "$HOME/.config/waybar/libniri_window_buttons.so"
            echo "✅ Installed niri-window-buttons to $HOME/.config/waybar/"
            echo "💡 Restart waybar or log out/in to apply changes"
        else
            echo "❌ Error: libniri_window_buttons.so not found in artifact"
            exit 1
        fi
        
        cd /
        rm -rf "$TEMP_DIR"
    else
        echo "❌ Error: Could not find niri-window-buttons artifact"
        exit 1
    fi

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
