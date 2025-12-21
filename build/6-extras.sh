#!/usr/bin/env bash
set -euo pipefail

# Validate YAML configuration
if [ ! -f "applets.yml" ]; then
    echo "ERROR: applets.yml not found in $(pwd)"
    echo "This file is required for YAML-driven package configuration"
    exit 1
fi

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

            # Custom installation scripts override
            if [ -f "install.sh" ]; then
                echo "Running custom install.sh for $applet_name"
                bash install.sh
                continue  # Skip to next applet
            elif [ -f "justfile" ] && command -v just >/dev/null 2>&1 && just --list 2>/dev/null | grep -q "install"; then
                echo "Running just install for $applet_name"
                just install
                continue  # Skip to next applet
            fi

            # Install binary if present (in target/release/ or root)
            # First try to find the expected binary name
            expected_binary_name="$applet_name"
            # Special case for emoji-selector
            if [ "$applet_name" = "cosmic-ext-applet-emoji-selector" ]; then
                expected_binary_name="cosmic-applet-emoji-selector"
                echo "Using special case: looking for cosmic-applet-emoji-selector"
            fi

            for binary in *cosmic*; do
                if [ -f "$binary" ] && [ -x "$binary" ]; then
                    install -Dm0755 "$binary" "/usr/bin/${expected_binary_name:-$binary}"
                    echo "Installed binary: ${expected_binary_name:-$binary} (from $binary)"
                    break
                fi
            done

            # Custom scripts override
            if [ -f "install.sh" ]; then
                echo "Running custom install.sh for $applet_name"
                bash install.sh || {
                    echo "ERROR: install.sh failed for $applet_name"
                    continue
                }
                continue
            elif [ -f "justfile" ] && command -v just >/dev/null 2>&1 && just --list 2>/dev/null | grep -q "install"; then
                echo "Running just install for $applet_name"
                just install || {
                    echo "ERROR: just install failed for $applet_name"
                    continue
                }
                continue
            fi

            # Simple binary detection with YAML integration
            binary_found=false
            for binary in *cosmic*; do
                if [ -f "$binary" ] && [ -x "$binary" ]; then
                    binary_found=true
                    # Extract expected binary name from applets.yml
                    expected_binary_name=$(yq eval ".applets[\"$applet_name\"].binary_names[0]" applets.yml 2>/dev/null || echo "")

                    # Install with expected name if available, otherwise use binary name
                    if [ -n "$expected_binary_name" ]; then
                        install -Dm0755 "$binary" "/usr/bin/${expected_binary_name}" || {
                            echo "ERROR: Failed to install $expected_binary_name"
                            # TODOs: continue 2
                        }
                        echo "Installed binary: ${expected_binary_name} (from $binary)"
                    else
                        install -Dm0755 "$binary" "/usr/bin/$binary" || {
                            echo "ERROR: Failed to install $binary"
                            # TODOs: continue 2
                        }
                        echo "Installed binary: $binary"
                    fi
                    break
                fi
            done

            if [ "$binary_found" = false ]; then
                echo "WARNING: No cosmic binaries found in $applet_name"
                continue
            fi

            # Install supporting files (simple approach)
            echo "Installing supporting files for $applet_name..."

            # Desktop files
            desktop_count=0
            for desktop_file in *.desktop; do
                if [ -f "$desktop_file" ]; then
                    install -Dm0644 "$desktop_file" "/usr/share/applications/$desktop_file" || {
                        echo "ERROR: Failed to install desktop file: $desktop_file"
                    }
                    echo "  Installed desktop file: $desktop_file"
                    desktop_count=$((desktop_count + 1))
                fi
            done
            if [ $desktop_count -eq 0 ]; then
                echo "  No desktop files found"
            fi

            # Metainfo files
            metainfo_count=0
            for metainfo_file in *.metainfo.xml; do
                if [ -f "$metainfo_file" ]; then
                    install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$metainfo_file" || {
                        echo "ERROR: Failed to install metainfo file: $metainfo_file"
                    }
                    echo "  Installed metainfo file: $metainfo_file"
                    metainfo_count=$((metainfo_count + 1))
                fi
            done
            if [ $metainfo_count -eq 0 ]; then
                echo "  No metainfo files found"
            fi

            # Icons (recursive)
            if [ -d "icons" ]; then
                mkdir -p "/usr/share/icons/hicolor" || {
                    echo "ERROR: Failed to create icons directory"
                }
                cp -r icons/* "/usr/share/icons/hicolor/" 2>/dev/null || {
                    echo "ERROR: Failed to copy icons"
                }
                icon_count=$(find icons -type f | wc -l)
                echo "  Installed $icon_count icons from icons/ directory"
            else
                echo "  No icons directory found"
            fi

            # Schema files if present
            if [ -d "schema" ]; then
                install -D -d "/usr/share/$applet_name/schema" || {
                    echo "ERROR: Failed to create schema directory"
                }
                cp -r schema/* "/usr/share/$applet_name/schema/" 2>/dev/null || {
                    echo "ERROR: Failed to copy schema files"
                }
                schema_count=$(find schema -type f | wc -l)
                echo "  Installed $schema_count schema files"
            fi

            # i18n files if present
            if [ -d "i18n-json" ]; then
                install -D -d "/usr/share/$applet_name/i18n-json" || {
                    echo "ERROR: Failed to create i18n directory"
                }
                cp -r i18n-json/* "/usr/share/$applet_name/i18n-json/" 2>/dev/null || {
                    echo "ERROR: Failed to copy i18n files"
                }
                i18n_count=$(find i18n-json -type f | wc -l)
                echo "  Installed $i18n_count i18n files"
            fi

            echo "Applet $applet_name installation completed"
            cd - > /dev/null
        fi
    done

    echo "All applets installed successfully"
else
    echo "No applet artifacts found, skipping applet installation"
    exit 0
fi

# Install the binary
# install -Dm755 "$CARGO_TARGET_DIR/release/cosmic-ext-bg-theme" /usr/bin/cosmic-ext-bg-theme
# Install desktop file
# install -Dm644 res/cosmic.ext.BgTheme.desktop /usr/share/applications/cosmic.ext.BgTheme.desktop

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
