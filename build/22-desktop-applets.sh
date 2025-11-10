#!/usr/bin/env bash
set -euo pipefail

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "Error occurred in script at line $line_number with exit code $exit_code"
    echo "Current applet being processed: ${applet_name:-unknown}"
    echo "Current working directory: $(pwd)"
    echo "Directory contents:"
    find . -maxdepth 2 -type f | head -20 || true
    exit $exit_code
}

# Set up error trap
trap 'handle_error $LINENO' ERR

echo "::group:: Install COSMIC Applets"

# Install cosmic-ext-classic-menu from COPR
echo "Installing cosmic-ext-classic-menu from championpeak87/cosmic-ext-classic-menu COPR..."
copr_install_isolated "championpeak87/cosmic-ext-classic-menu" cosmic-ext-classic-menu
echo "cosmic-ext-classic-menu installed from COPR"

# Install cosmic-ext-applet-yt-dlp from GitHub release
echo "Installing cosmic-ext-applet-yt-dlp from GitHub release..."
cd /tmp
LATEST_RELEASE=$(curl -s https://api.github.com/repos/D-Brox/cosmic-ext-applet-yt-dlp/releases/latest | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//')
if [ -n "$LATEST_RELEASE" ]; then
    echo "Latest release: $LATEST_RELEASE"
    RPM_URL="https://github.com/D-Brox/cosmic-ext-applet-yt-dlp/releases/download/$LATEST_RELEASE/cosmic-ext-applet-yt-dlp-0.1.1-1.x86_64.rpm"
    echo "Downloading RPM from: $RPM_URL"
    if curl -L -o cosmic-ext-applet-yt-dlp.rpm "$RPM_URL"; then
        dnf5 install -y cosmic-ext-applet-yt-dlp.rpm
        echo "cosmic-ext-applet-yt-dlp installed successfully"
        rm -f cosmic-ext-applet-yt-dlp.rpm
    else
        echo "Failed to download cosmic-ext-applet-yt-dlp RPM"
    fi
else
    echo "Failed to fetch latest release information for cosmic-ext-applet-yt-dlp"
fi

# Install cosmic-ext-applet-privacy-indicator from GitHub release
echo "Installing cosmic-ext-applet-privacy-indicator from GitHub release..."
LATEST_RELEASE=$(curl -s https://api.github.com/repos/D-Brox/cosmic-ext-applet-privacy-indicator/releases/latest | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//')
if [ -n "$LATEST_RELEASE" ]; then
    echo "Latest release: $LATEST_RELEASE"
    RPM_URL="https://github.com/D-Brox/cosmic-ext-applet-privacy-indicator/releases/download/$LATEST_RELEASE/cosmic-ext-applet-privacy-indicator-0.1.2-1.x86_64.rpm"
    echo "Downloading RPM from: $RPM_URL"
    if curl -L -o cosmic-ext-applet-privacy-indicator.rpm "$RPM_URL"; then
        dnf5 install -y cosmic-ext-applet-privacy-indicator.rpm
        echo "cosmic-ext-applet-privacy-indicator installed successfully"
        rm -f cosmic-ext-applet-privacy-indicator.rpm
    else
        echo "Failed to download cosmic-ext-applet-privacy-indicator RPM"
    fi
else
    echo "Failed to fetch latest release information for cosmic-ext-applet-privacy-indicator"
fi

# Install applets from artifacts if they exist
if [ -d "/applets" ] && [ "$(ls -A /applets)" ]; then
    echo "Installing applets from artifacts..."
    
    # Extract ZIP files if present
    for zip_file in /applets/*.zip; do
        if [ -f "$zip_file" ]; then
            applet_name=$(basename "$zip_file" .zip)
            echo "Extracting $applet_name..."
            # Convert underscores back to hyphens for directory naming consistency
            applet_dir_name=${applet_name//_/-}
            # Extract to temp directory first to handle nested structure
            temp_dir="/tmp/$applet_name"
            mkdir -p "$temp_dir"
            unzip -q "$zip_file" -d "$temp_dir"
            
            # Move contents up one level if there's a single nested directory
            # ZIP contains: cosmic-ext-applet-privacy-indicator/
            # We want: /applets/cosmic-ext-applet-privacy-indicator/
            nested_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
            if [ -n "$nested_dir" ] && [ "$(find "$temp_dir" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
                echo "Moving contents from nested directory..."
                mv "$nested_dir" "/applets/$applet_dir_name"
            else
                echo "No nested directory found, moving all contents..."
                mkdir -p "/applets/$applet_dir_name"
                mv "$temp_dir"/* "/applets/$applet_dir_name/"
            fi
            rmdir "$temp_dir"
            rm "$zip_file"  # Remove ZIP after extraction
            
            # Log extracted contents
            echo "Extracted files for $applet_name:"
            if [ -d "/applets/$applet_dir_name" ]; then
                # List binaries
                find "/applets/$applet_dir_name" -maxdepth 2 -name "cosmic*" -type f -executable | while read -r binary; do
                    echo "  Binary: $(basename "$binary")"
                done
                # List justfile
                if [ -f "/applets/$applet_dir_name/justfile" ]; then
                    echo "  Justfile: justfile"
                fi
                # List supporting files and directories
                find "/applets/$applet_dir_name" -maxdepth 1 -type f \( -name "*.desktop" -o -name "*.metainfo.xml" -o -name "*.toml" -o -name "*.json" \) | while read -r file; do
                    echo "  Supporting File: $(basename "$file")"
                done
                find "/applets/$applet_dir_name" -maxdepth 1 -type d ! -path "/applets/$applet_dir_name" | while read -r dir; do
                    echo "  Supporting Directory: $(basename "$dir")"
                done
            fi
        fi
    done
    
    # Install 'just' if not available
    if ! command -v just >/dev/null 2>&1; then
        echo "Installing 'just'..."
        dnf5 install -y just
    fi
    
    for applet_dir in /applets/*/; do
        if [ -d "$applet_dir" ]; then
            applet_name=$(basename "$applet_dir")
            echo "Installing applet: $applet_name"
            
            
            
            cd "$applet_dir"
            
            echo "Current directory contents:"
            find . -maxdepth 2 -type f | head -20 || true
            echo ""
            
            # Install binary if present (in target/release/ or root)
            # First try to find the expected binary name
            expected_binary_name="$applet_name"
            # Special case for emoji-selector
            if [ "$applet_name" = "cosmic-ext-applet-emoji-selector" ]; then
                expected_binary_name="cosmic-applet-emoji-selector"
                echo "Using special case: looking for cosmic-applet-emoji-selector"
            fi
            # Special case for music-player
            if [ "$applet_name" = "cosmic-applet-music-player" ]; then
                expected_binary_name="cosmic-ext-applet-music-player"
                echo "Using special case: looking for cosmic-ext-applet-music-player"
            fi

            # Function to search for binary in a specific directory
            search_binary() {
                local search_dir="$1"
                local binary_name="$2"
                echo "Searching for $binary_name in $search_dir..." >&2
                if [ -d "$search_dir" ]; then
                    find "$search_dir" -maxdepth 1 -name "$binary_name" -type f -executable | head -1
                else
                    echo "Directory $search_dir does not exist" >&2
                fi
            }

            echo "Searching for binary: $expected_binary_name in current directory..."
            binary=$(search_binary "." "$expected_binary_name")
            
            if [ -z "$binary" ]; then
                echo "Binary not found, trying justfile name variable..."
                # Try to find from justfile name variable
                if [ -f "justfile" ]; then
                    echo "Justfile contents (first 10 lines):"
                    head -10 justfile | sed 's/^/  /' || true
                    echo ""
                    justfile_name=$(grep "^name :=" justfile | sed "s/name := '//" | sed "s/'//")
                    if [ -n "$justfile_name" ]; then
                        echo "Found justfile name: $justfile_name"
                        binary=$(search_binary "." "$justfile_name")
                    else
                        echo "No name variable found in justfile with pattern '^name :='"
                        # Try alternative patterns for name
                        justfile_name=$(grep "^name\s*=" justfile | sed 's/^name\s*=\s*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//')
                        if [ -n "$justfile_name" ]; then
                            echo "Found justfile name with alternative pattern: $justfile_name"
                            binary=$(search_binary "." "$justfile_name")
                        else
                            echo "No name variable found, trying to extract binary name from install target..."
                            # Look for install target to find binary name
                            install_binary=$(grep -A 5 "^install:" justfile | grep "install.*target/release.*" | sed 's/.*target\/release\/\([^[:space:]]*\).*/\1/' | head -1)
                            if [ -n "$install_binary" ]; then
                                echo "Found binary in install target: $install_binary"
                                binary=$(search_binary "." "$install_binary")
                            else
                                echo "No binary found in install target, trying id variable..."
                                # Try id variable (used by emoji selector)
                                justfile_id=$(grep "^id\s*=" justfile | sed 's/^id\s*=\s*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//')
                                if [ -n "$justfile_id" ]; then
                                    echo "Found justfile id: $justfile_id"
                                    # Extract applet name from id (last part after dots)
                                    justfile_name=${justfile_id##*.}
                                    echo "Extracted name from id: $justfile_name"
                                    binary=$(search_binary "." "$justfile_name")
                                else
                                    echo "No name or id variable found in justfile"
                                fi
                            fi
                        fi
                    fi
                else
                    echo "No justfile found"
                fi
            fi
            
            if [ -z "$binary" ]; then
                echo "Not found with justfile name, searching for any cosmic binary..."
                # Fallback to generic cosmic search
                binary=$(search_binary "." "cosmic*")
            fi
            
            if [ -n "$binary" ]; then
            echo "Found binary: $binary"
            binary_name=$(basename "$binary")
            # Use proper applet names instead of hash-suffixed binaries
                case "$applet_name" in
                    "cosmic-connect-applet")
                        install -Dm0755 "$binary" "/usr/bin/cosmic-connect-applet"
                        echo "Installed binary: cosmic-connect-applet (from $binary_name)"
                        ;;
                    "cosmic-ext-applet-ollama")
                        install -Dm0755 "$binary" "/usr/bin/cosmic-ext-applet-ollama"
                        echo "Installed binary: cosmic-ext-applet-ollama (from $binary_name)"
                        ;;
                    "cosmic-ext-applet-privacy-indicator")
                        install -Dm0755 "$binary" "/usr/bin/cosmic-ext-applet-privacy-indicator"
                        echo "Installed binary: cosmic-ext-applet-privacy-indicator (from $binary_name)"
                        ;;
                    "cosmic-ext-applet-emoji-selector")
                        install -Dm0755 "$binary" "/usr/bin/cosmic-ext-applet-emoji-selector"
                        echo "Installed binary: cosmic-ext-applet-emoji-selector (from $binary_name)"
                        ;;
                    "cosmic-applet-music-player")
                        install -Dm0755 "$binary" "/usr/bin/cosmic-ext-applet-music-player"
                        echo "Installed binary: cosmic-ext-applet-music-player (from $binary_name)"
                        ;;
                    "wf-recorder-gui")
                        # Install wf-recorder-gui from artifacts
                        if [ -f "wf-recorder-gui" ]; then
                            install -Dm755 wf-recorder-gui /usr/bin/wf-recorder-gui
                            echo "Installed binary: wf-recorder-gui"
                        else
                            echo "wf-recorder-gui binary not found in artifacts"
                        fi
                        
                        # Install desktop file if present
                        if [ -f "wf-recorder-gui.desktop" ]; then
                            install -Dm644 wf-recorder-gui.desktop /usr/share/applications/wf-recorder-gui.desktop
                            echo "Installed desktop file: wf-recorder-gui.desktop"
                        else
                            echo "wf-recorder-gui.desktop not found in artifacts"
                        fi
                        ;;
                    *)
                        install -Dm0755 "$binary" "/usr/bin/$binary_name"
                        echo "Installed binary: $binary_name"
                        ;;
                esac
            fi
            
            # Only run just install if we didn't already install a binary
            if [ -f "justfile" ] && just --list 2>/dev/null | grep -q "install" && [ -z "$binary" ]; then
                echo "Running just install for $applet_name"
                just install
            elif [ -f "install.sh" ]; then
                echo "Running install.sh for $applet_name"
                bash install.sh
            else
                echo "No justfile install target or install.sh found, performing manual installation..."
                
                # Manual installation based on preserved structure
                
                # Install desktop files, checking multiple directories
                if [ -d "res" ]; then
                    desktop_files=$(find res -name "*.desktop" -type f 2>/dev/null)
                fi
                if [ -z "$desktop_files" ] && [ -d "data" ]; then
                    desktop_files=$(find data -name "*.desktop" -type f 2>/dev/null)
                fi
                if [ -z "$desktop_files" ]; then
                    desktop_files=$(find . -maxdepth 1 -name "*.desktop" -type f 2>/dev/null)
                fi
                if [ -n "$desktop_files" ]; then
                    echo "Installing desktop files..."
                    echo "$desktop_files" | while read -r desktop_file; do
                        if [ -f "$desktop_file" ]; then
                            install -Dm0644 "$desktop_file" "/usr/share/applications/$(basename "$desktop_file")"
                            echo "  Installed desktop file: $(basename "$desktop_file")"
                        else
                            echo "  Warning: Desktop file not found: $desktop_file"
                        fi
                    done
                else
                    echo "No desktop files found for $applet_name"
                fi
                
                # Install metainfo files, prioritizing res/ over root to avoid duplicates
                if [ -d "res" ]; then
                    metainfo_files=$(find res -name "*.metainfo.xml" -type f 2>/dev/null)
                fi
                if [ -z "$metainfo_files" ]; then
                    metainfo_files=$(find . -maxdepth 1 -name "*.metainfo.xml" -type f 2>/dev/null)
                fi
                if [ -n "$metainfo_files" ]; then
                    echo "Installing metainfo files..."
                    echo "$metainfo_files" | while read -r metainfo_file; do
                        install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$(basename "$metainfo_file")"
                        echo "  Installed metainfo file: $(basename "$metainfo_file")"
                    done
                fi
                
                # Install icons from their original structure
                if [ -d "res/icons" ]; then
                    echo "Installing icons from res/icons..."
                    find res/icons -type f | while read -r icon_file; do
                        relative_path="${icon_file#res/icons/}"
                        install -Dm0644 "$icon_file" "/usr/share/icons/hicolor/$relative_path"
                        echo "  Installed icon: $relative_path"
                    done
                elif [ -d "data/icons" ]; then
                    echo "Installing icons from data/icons..."
                    find data/icons -type f | while read -r icon_file; do
                        relative_path="${icon_file#data/icons/}"
                        install -Dm0644 "$icon_file" "/usr/share/icons/hicolor/$relative_path"
                        echo "  Installed icon: $relative_path"
                    done
                fi
                
                # Install i18n files from their original structure
                if [ -d "i18n-json" ]; then
                    echo "Installing i18n files..."
                    find i18n-json -type f | while read -r i18n_file; do
                        relative_path="${i18n_file#i18n-json/}"
                        install -Dm0644 "$i18n_file" "/usr/share/$applet_name/i18n-json/$relative_path"
                        echo "  Installed i18n file: $relative_path"
                    done
                fi
                
                # Install schema files if present
                if [ -d "data/schema" ]; then
                    echo "Installing schema files..."
                    find data/schema -type f | while read -r schema_file; do
                        relative_path="${schema_file#data/schema/}"
                        install -Dm0644 "$schema_file" "/usr/share/$applet_name/schema/$relative_path"
                        echo "  Installed schema file: $relative_path"
                    done
                fi
            fi
        fi
    done
    
    echo "Applet installation completed."
else
    echo "No applet artifacts found, skipping applet installation."
fi

echo "::endgroup::"