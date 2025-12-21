#!/usr/bin/env bash
set -euo pipefail

echo "===$(basename "$0")==="
echo "::group:: COSMIC Applets RPM"
echo "Installing cosmic-ext-applet-yt-dlp RPM..."
# Get the latest RPM URL from GitHub Releases
YTDLP_URL=$(curl -s "https://api.github.com/repos/D-Brox/cosmic-ext-applet-yt-dlp/releases/latest" | grep "browser_download_url.*cosmic-ext-applet-yt-dlp.*\x86_64.rpm" | cut -d '"' -f 4)
curl -L -o cosmic-ytdlp-applet.rpm "$YTDLP_URL"
dnf5 install -y ./cosmic-ytdlp-applet.rpm
rm -f cosmic-ytdlp-applet.rpm
echo "::endgroup::"

echo "::group:: COSMIC Applets Artifacts"

# Install applets from artifacts if they exist
if [ -d "/applets" ] && [ "$(ls -A /applets)" ]; then
    echo "Installing applets from artifacts..."

    # Extract ZIP files if present
    for zip_file in /applets/*.zip; do
        if [ -f "$zip_file" ]; then
            applet_name=$(basename "$zip_file" .zip)
            echo "Extracting $applet_name..."

            # Extract applets to temp dir
            applet_dir_name=${applet_name//_/-}
            temp_dir="/tmp/$applet_name"
            mkdir -p "$temp_dir"
            unzip -q "$zip_file" -d "$temp_dir"

            # Handle nested directory structure
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
            rm "$zip_file"

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
            # Extract expected binary name from applets.yml
            expected_binary_name=$(yq eval ".applets[\"$applet_name\"].binary_names[0]" applets.yml)
            # Use proper applet names instead of hash-suffixed binaries
                case "$applet_name" in
                    # Combine all 8 packages into one case
                    "cosmic-ext-applet-privacy-indicator"|"cosmic-ext-applet-emoji-selector"|"cosmic-ext-applet-vitals"|"cosmic-ext-applet-caffeine"|"cosmic-ext-applet-clipboard-manager"|"cosmic-ext-alternative-startup"|"wf-recorder-gui"|"cosmic-ext-bg-theme")
                        install -Dm0755 "$binary" "/usr/bin/${expected_binary_name}"
                        echo "Installed binary: ${expected_binary_name} (from $binary_name)"
                        ;;
                    "wf-recorder-gui")
                        if [ -f "wf-recorder-gui" ]; then
                            install -Dm755 wf-recorder-gui /usr/bin/${expected_binary_name}
                            echo "Installed binary: ${expected_binary_name}"
                        else
                            echo "wf-recorder-gui binary not found in artifacts"
                        fi
                        # Install desktop file from metadata or fallback
                        if [ -f "wf-recorder-gui.desktop" ]; then
                            install -Dm644 wf-recorder-gui.desktop /usr/share/applications/wf-recorder-gui.desktop
                            echo "Installed desktop file: wf-recorder-gui.desktop"
                        else
                            echo "wf-recorder-gui.desktop not found in artifacts"
                        fi
                        ;;
                    "cosmic-ext-alternative-startup")
                        if [ -f "cosmic-ext-alternative-startup" ]; then
                            install -Dm755 cosmic-ext-alternative-startup /usr/bin/${expected_binary_name}
                            echo "Installed binary: ${expected_binary_name}"
                        else
                            echo "cosmic-ext-alternative-startup binary not found in artifacts"
                        fi
                        # Check for desktop file in common locations
                        if [ -f "res/cosmic.ext.AlternativeStartup.desktop" ]; then
                            install -Dm644 res/cosmic.ext.AlternativeStartup.desktop /usr/share/applications/cosmic.ext.AlternativeStartup.desktop
                            echo "Installed desktop file: cosmic.ext.AlternativeStartup.desktop"
                        elif [ -f "cosmic.ext.AlternativeStartup.desktop" ]; then
                            install -Dm644 cosmic.ext.AlternativeStartup.desktop /usr/share/applications/cosmic.ext.AlternativeStartup.desktop
                            echo "Installed desktop file: cosmic.ext.AlternativeStartup.desktop"
                        else
                            echo "No desktop file found for ${applet_name}"
                        fi
                        ;;
                    "cosmic-ext-bg-theme")
                         if [ -f "cosmic-ext-bg-theme" ]; then
                             install -Dm755 cosmic-ext-bg-theme /usr/bin/${expected_binary_name}
                             echo "Installed binary: ${expected_binary_name}"
                         else
                             echo "cosmic-ext-bg-theme binary not found in artifacts"
                         fi
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
                esac

                # Install supporting files based on metadata patterns
                echo "Installing supporting files from metadata..."
                if [ -n "$expected_binary_name" ]; then
                    # Install desktop files
                    desktop_files=$(find . -maxdepth 3 -name "*.desktop" -type f 2>/dev/null | head -5)
                    if [ -n "$desktop_files" ]; then
                        echo "Found desktop files:"
                        echo "$desktop_files" | while read -r desktop_file; do
                            if [ -f "$desktop_file" ]; then
                                install -Dm0644 "$desktop_file" "/usr/share/applications/$(basename "$desktop_file")"
                                echo "  Installed desktop file: $(basename "$desktop_file")"
                            fi
                        done
                    else
                        echo "No desktop files found"
                    fi

                    # Install metainfo files
                    metainfo_files=$(find . -maxdepth 3 -name "*.metainfo.xml" -type f 2>/dev/null | head -5)
                    if [ -n "$metainfo_files" ]; then
                        echo "Found metainfo files:"
                        echo "$metainfo_files" | while read -r metainfo_file; do
                            install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$(basename "$metainfo_file")"
                            echo "  Installed metainfo file: $(basename "$metainfo_file")"
                        done
                    else
                        echo "No metainfo files found"
                    fi

                    # Install icons if they exist in common locations
                    for icon_dir in "res/icons" "icons" "data/icons"; do
                        if [ -d "$icon_dir" ]; then
                            echo "Installing icons from $icon_dir..."
                            find "$icon_dir" -type f | while read -r icon_file; do
                                relative_path="${icon_file#$icon_dir/}"
                                install -Dm0644 "$icon_file" "/usr/share/icons/hicolor/$relative_path"
                                echo "  Installed icon: $relative_path"
                            done
                            break
                        fi
                    done

                    # Install i18n files if present
                    if [ -d "i18n-json" ]; then
                        echo "Installing i18n files..."
                        find i18n-json -type f | while read -r i18n_file; do
                            relative_path="${i18n_file#i18n-json/}"
                            install -Dm0644 "$i18n_file" "/usr/share/$expected_binary_name/i18n-json/$relative_path"
                            echo "  Installed i18n file: $relative_path"
                        done
                    fi

                    # Install schema files if present
                    if [ -d "data/schema" ]; then
                        echo "Installing schema files..."
                        find data/schema -type f | while read -r schema_file; do
                            relative_path="${schema_file#data/schema/}"
                            install -Dm0644 "$schema_file" "/usr/share/$expected_binary_name/schema/$relative_path"
                            echo "  Installed schema file: $relative_path"
                        done
                    fi
                fi
            fi
        done

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
    done

    echo "Applet installation completed."
else
    echo "No applet artifacts found, skipping applet installation."
fi

echo "::endgroup::"

echo "::group:: Install OpenCode Desktop & Wave Terminal"

echo "Installing latest OpenCode RPM..."
cd /tmp
curl -L -o oc.rpm "https://github.com/sst/opencode/releases/latest/download/opencode-desktop-linux-x86_64.rpm"
dnf5 install -y ./oc.rpm
rm -f oc.rpm

echo "Installing latest Wave Terminal RPM..."
# Get the latest Wave Terminal release RPM URL
WAVE_URL=$(curl -s "https://api.github.com/repos/wavetermdev/waveterm/releases/latest" | grep "browser_download_url.*waveterm-linux-x86_64.*\.rpm" | cut -d '"' -f 4)
curl -L -o wave.rpm "$WAVE_URL"
dnf5 install -y ./wave.rpm
rm -f wave.rpm

echo "::endgroup::"
