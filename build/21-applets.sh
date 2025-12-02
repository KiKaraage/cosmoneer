#!/usr/bin/env bash
set -euo pipefail

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Install COSMIC Applets"

# Install common dependencies for GitHub release RPMs
echo "Installing common dependencies for applet RPMs..."
dnf5 install -y glibc openssl-libs || echo "Some dependencies may already be installed"


# Install cosmic-ext-applet-yt-dlp from GitHub release
# TEMPORARILY COMMENTED OUT due to dependency issues (nscd, openssl3-libs)
# echo "Installing cosmic-ext-applet-yt-dlp from GitHub release..."
# cd /tmp
# LATEST_RELEASE=$(curl -s https://api.github.com/repos/D-Brox/cosmic-ext-applet-yt-dlp/releases/latest | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//')
# if [ -n "$LATEST_RELEASE" ]; then
#     echo "Latest release: $LATEST_RELEASE"
#     RPM_URL="https://github.com/D-Brox/cosmic-ext-applet-yt-dlp/releases/download/$LATEST_RELEASE/cosmic-ext-applet-yt-dlp-0.1.1-1.x86_64.rpm"
#     echo "Downloading RPM from: $RPM_URL"
#     if curl -L -o cosmic-ext-applet-yt-dlp.rpm "$RPM_URL"; then
#         dnf5 install -y cosmic-ext-applet-yt-dlp.rpm
#         echo "cosmic-ext-applet-yt-dlp installed successfully"
#         rm -f cosmic-ext-applet-yt-dlp.rpm
#     else
#         echo "Failed to download cosmic-ext-applet-yt-dlp RPM"
#     fi
# else
#     echo "Failed to fetch latest release information for cosmic-ext-applet-yt-dlp"
# fi

# Install cosmic-ext-applet-privacy-indicator from GitHub release
echo "Installing cosmic-ext-applet-privacy-indicator from GitHub release..."

# Check if curl is available
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not available, skipping cosmic-ext-applet-privacy-indicator installation"
else
    # Get the latest release assets
    RELEASE_API_URL="https://api.github.com/repos/D-Brox/cosmic-ext-applet-privacy-indicator/releases/latest"
    echo "Fetching latest release assets from: $RELEASE_API_URL"
    
    # Find the first x86_64 RPM in the latest release assets
    RPM_URL=$(curl -s "$RELEASE_API_URL" | grep -o '"browser_download_url": "[^"]*x86_64\.rpm"' | sed 's/"browser_download_url": "//;s/"$//' | head -1)
    
    if [ -n "$RPM_URL" ]; then
        echo "Found x86_64 RPM: $RPM_URL"
        if curl -L -f -o cosmic-ext-applet-privacy-indicator.rpm "$RPM_URL"; then
            dnf5 install -y cosmic-ext-applet-privacy-indicator.rpm
            echo "cosmic-ext-applet-privacy-indicator installed successfully"
            rm -f cosmic-ext-applet-privacy-indicator.rpm
        else
            echo "Failed to download cosmic-ext-applet-privacy-indicator RPM, continuing without it"
        fi
    else
        echo "No x86_64 RPM found in latest release assets, continuing without it"
    fi
fi

# Install applets from artifacts if they exist
if [ -d "/applets" ] && [ "$(ls -A /applets)" ]; then
    echo "Installing applets from artifacts..."
    
    # Extract ZIP files if present
    for zip_file in /applets/*.zip; do
        if [ -f "$zip_file" ]; then
            applet_name=$(basename "$zip_file" .zip)
            echo "Extracting $applet_name..."
            
            # Special handling for niri_window_buttons - direct .so file
            if [ "$applet_name" = "niri_window_buttons" ]; then
                # Extract directly to the applet directory
                unzip -q "$zip_file" -d "/applets/niri_window_buttons/"
                echo "Extracted niri_window_buttons .so file directly"
            else
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
            fi
            rm "$zip_file"  # Remove ZIP after extraction
            
            # Log extracted contents
            echo "Extracted files for $applet_name:"
            if [ "$applet_name" = "niri_window_buttons" ]; then
                # List .so file
                find "/applets/niri_window_buttons" -name "*.so" -type f | while read -r so_file; do
                    echo "  .so file: $(basename "$so_file")"
                done
            elif [ -d "/applets/$applet_dir_name" ]; then
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
        rm -rf /usr/share/doc/just
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
                    "cosmic-ext-bg-theme")
                         # Install cosmic-ext-bg-theme from artifacts
                         if [ -f "cosmic-ext-bg-theme" ]; then
                             install -Dm755 cosmic-ext-bg-theme /usr/bin/cosmic-ext-bg-theme
                             echo "Installed binary: cosmic-ext-bg-theme"
                         else
                             echo "cosmic-ext-bg-theme binary not found in artifacts"
                         fi
                         
                         # Install desktop file if present
                         if [ -f "res/cosmic.ext.BgTheme.desktop" ]; then
                             install -Dm644 res/cosmic.ext.BgTheme.desktop /usr/share/applications/cosmic.ext.BgTheme.desktop
                             echo "Installed desktop file: cosmic.ext.BgTheme.desktop"
                         elif [ -f "cosmic.ext.BgTheme.desktop" ]; then
                             install -Dm644 cosmic.ext.BgTheme.desktop /usr/share/applications/cosmic.ext.BgTheme.desktop
                             echo "Installed desktop file: cosmic.ext.BgTheme.desktop"
                         else
                             echo "cosmic.ext.BgTheme.desktop not found in artifacts"
                         fi
                         ;;
                    "prtsc-wayland")
                         # Install prtsc-wayland from artifacts
                         if [ -f "prtsc-wayland" ]; then
                             install -Dm755 prtsc-wayland /usr/bin/prtsc-wayland
                             echo "Installed binary: prtsc-wayland"
                         else
                             echo "prtsc-wayland binary not found in artifacts"
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
                desktop_files=""
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
                metainfo_files=""
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
    
    # Special handling for niri_window_buttons (so file)
    if [ "$applet_name" = "niri_window_buttons" ]; then
        echo "Installing niri_window_buttons..."
        # Look for the .so file directly in the applet directory
        so_file=$(find "$applet_dir" -name "libniri_window_buttons.so" -type f | head -1)
        if [ -n "$so_file" ]; then
            # Copy to skel directory for waybar config
            mkdir -p /etc/skel/.config/waybar/
            cp "$so_file" /etc/skel/.config/waybar/libniri_window_buttons.so
            echo "Copied .so file to skel directory for waybar config"
        else
            echo "Error: libniri_window_buttons.so not found in applet directory"
            exit 1
        fi
    fi
    
    echo "Applet installation completed."
else
    echo "No applet artifacts found, skipping applet installation."
fi

echo "::endgroup::"