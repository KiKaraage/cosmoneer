#!/usr/bin/env bash
set -euo pipefail

echo "===$(basename "$0")==="
echo "::group:: COSMIC Applets Artifacts"

# Validate YAML configuration
if [ ! -f "applets.yml" ]; then
    echo "ERROR: applets.yml not found in $(pwd)"
    echo "This file is required for YAML-driven package configuration"
    exit 1
fi

# Install applets from artifacts if they exist
if [ -d "/applets" ] && [ "$(ls -A /applets)" ]; then
    echo "Installing applets from artifacts..."

    # First, organize loose files into directories by applet name
    echo "Organizing artifacts into directories..."

    # Define mapping of files to applets
    declare -A file_to_applet=(
        ["cosmic-applet-emoji-selector"]="cosmic-ext-applet-emoji-selector"
        ["cosmic-ext-alternative-startup"]="cosmic-ext-alternative-startup"
        ["cosmic-ext-applet-caffeine"]="cosmic-ext-applet-caffeine"
        ["cosmic-ext-applet-clipboard-manager"]="cosmic-ext-applet-clipboard-manager"
        ["cosmic-ext-applet-privacy-indicator"]="cosmic-ext-applet-privacy-indicator"
        ["cosmic-ext-applet-vitals"]="cosmic-ext-applet-vitals"
        ["cosmic-ext-bg-theme"]="cosmic-ext-bg-theme"
        ["wf-recorder-gui"]="wf-recorder-gui"
    )

    # Create directories and move files
    for filename in "${!file_to_applet[@]}"; do
        applet_dir="${file_to_applet[$filename]}"
        if [ -f "/applets/$filename" ]; then
            mkdir -p "/applets/$applet_dir"
            echo "Moving $filename to $applet_dir/"
            mv "/applets/$filename" "/applets/$applet_dir/"
        fi
    done

    # Also handle files with hash suffixes (Cargo artifacts)
    for file in /applets/*; do
        if [ -f "$file" ] && [[ "$(basename "$file")" =~ ^(cosmic.*|wf-recorder-gui)-[a-f0-9]+$ ]]; then
            # Extract base name without hash
            base_name=$(basename "$file" | sed 's/-[a-f0-9]*$//')
            if [ -n "${file_to_applet[$base_name]}" ]; then
                applet_dir="${file_to_applet[$base_name]}"
                mkdir -p "/applets/$applet_dir"
                echo "Moving $(basename "$file") to $applet_dir/"
                mv "$file" "/applets/$applet_dir/"
            fi
        fi
    done

    echo "Organization complete."

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

    # Define valid applet names to avoid processing non-applet directories
    VALID_APPLETS="cosmic-ext-applet-emoji-selector cosmic-ext-applet-privacy-indicator cosmic-ext-applet-vitals cosmic-ext-applet-caffeine cosmic-ext-applet-clipboard-manager cosmic-ext-alternative-startup wf-recorder-gui cosmic-ext-bg-theme"

    for applet_dir in /applets/*/; do
        if [ -d "$applet_dir" ]; then
            applet_name=$(basename "$applet_dir")
            # Skip directories that are not valid applets
            if ! echo "$VALID_APPLETS" | grep -q -w "$applet_name"; then
                echo "Skipping non-applet directory: $applet_name"
                continue
            fi
            echo "Installing applet: $applet_name"
            cd "$applet_dir"

            echo "Current directory contents:"
            find . -maxdepth 2 -type f | head -20 || true

            # Custom installation scripts override
            if [ -f "install.sh" ]; then
                echo "Running custom install.sh for $applet_name"
                bash install.sh
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

            # Look for the expected binary name (or with hash suffix for Cargo artifacts)
            found_binary=""
            for file in *; do
                if [ -f "$file" ] && [ -x "$file" ] && [[ "$file" == "$expected_binary_name" || "$file" == "$expected_binary_name"-* ]]; then
                    found_binary="$file"
                    break
                fi
            done

            if [ -n "$found_binary" ]; then
                install -Dm0755 "$found_binary" "/usr/bin/${expected_binary_name}"
                echo "Installed binary: ${expected_binary_name} (from $found_binary)"
            else
                echo "WARNING: Expected binary $expected_binary_name not found"
            fi


            # Simple binary detection with YAML integration
            binary_found=false
            # Determine if this is an applet or utility and get expected binary names
            SECTION=""
            if [[ "$applet_name" == *"applet"* ]]; then
                SECTION="applets"
            else
                SECTION="utilities"
            fi

            # Get expected binary names from YAML
            expected_binaries=$(yq eval ".$SECTION[\"$applet_name\"].binary_names[]" applets.yml 2>/dev/null || echo "")

            # If no binaries found in YAML, look for any executable files
            if [ -z "$expected_binaries" ]; then
                echo "No binary names found in YAML, looking for any executable files..."
                for binary in *; do
                    if [ -f "$binary" ] && [ -x "$binary" ] && [[ "$binary" != *.so ]] && [[ "$binary" != justfile ]]; then
                        expected_binaries="$binary"
                        break
                    fi
                done
            fi

            # Install binaries
            for expected_binary in $expected_binaries; do
                # Look for the binary (could be exact name or with hash suffix)
                found_binary=""
                for file in *; do
                    if [ -f "$file" ] && [ -x "$file" ] && [[ "$file" == "$expected_binary" || "$file" == "$expected_binary"-* ]]; then
                        found_binary="$file"
                        break
                    fi
                done

                if [ -n "$found_binary" ]; then
                    binary_found=true
                    install -Dm0755 "$found_binary" "/usr/bin/${expected_binary}" || {
                        echo "ERROR: Failed to install $expected_binary"
                    }
                    echo "Installed binary: ${expected_binary} (from $found_binary)"
                else
                    echo "WARNING: Expected binary $expected_binary not found"
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
            # Check root directory
            for desktop_file in *.desktop; do
                if [ -f "$desktop_file" ]; then
                    install -Dm0644 "$desktop_file" "/usr/share/applications/$desktop_file" || {
                        echo "ERROR: Failed to install desktop file: $desktop_file"
                    }
                    echo "  Installed desktop file: $desktop_file"
                    desktop_count=$((desktop_count + 1))
                fi
            done
            # Check res directory
            if [ -d "res" ]; then
                for desktop_file in res/*.desktop; do
                    if [ -f "$desktop_file" ]; then
                        filename=$(basename "$desktop_file")
                        install -Dm0644 "$desktop_file" "/usr/share/applications/$filename" || {
                            echo "ERROR: Failed to install desktop file: $filename"
                        }
                        echo "  Installed desktop file: $filename"
                        desktop_count=$((desktop_count + 1))
                    fi
                done
            fi
            if [ $desktop_count -eq 0 ]; then
                echo "  No desktop files found"
            fi

            # Metainfo files
            metainfo_count=0
            # Check root directory
            for metainfo_file in *.metainfo.xml; do
                if [ -f "$metainfo_file" ]; then
                    install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$metainfo_file" || {
                        echo "ERROR: Failed to install metainfo file: $metainfo_file"
                    }
                    echo "  Installed metainfo file: $metainfo_file"
                    metainfo_count=$((metainfo_count + 1))
                fi
            done
            # Check res directory
            if [ -d "res" ]; then
                for metainfo_file in res/*.metainfo.xml; do
                    if [ -f "$metainfo_file" ]; then
                        filename=$(basename "$metainfo_file")
                        install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$filename" || {
                            echo "ERROR: Failed to install metainfo file: $filename"
                        }
                        echo "  Installed metainfo file: $filename"
                        metainfo_count=$((metainfo_count + 1))
                    fi
                done
            fi
            if [ $metainfo_count -eq 0 ]; then
                echo "  No metainfo files found"
            fi

            # Icons (recursive)
            icon_installed=false

            # Check for icons directory (standard location)
            if [ -d "icons" ]; then
                mkdir -p "/usr/share/icons/hicolor" || {
                    echo "ERROR: Failed to create icons directory"
                }
                cp -r icons/* "/usr/share/icons/hicolor/" 2>/dev/null || {
                    echo "ERROR: Failed to copy icons from icons/"
                }
                icon_count=$(find icons -type f | wc -l)
                echo "  Installed $icon_count icons from icons/ directory"
                icon_installed=true
            fi

            # Check for res directory (alternative location)
            if [ -d "res" ]; then
                mkdir -p "/usr/share/icons/hicolor" || {
                    echo "ERROR: Failed to create icons directory"
                }
                # Copy SVG and PNG files from res directory
                find res -name "*.svg" -o -name "*.png" | while read -r icon_file; do
                    # Determine icon size from filename or use scalable
                    if [[ "$icon_file" =~ ([0-9]+)x[0-9]+ ]]; then
                        size="${BASH_REMATCH[1]}x${BASH_REMATCH[1]}"
                    else
                        size="scalable"
                    fi
                    mkdir -p "/usr/share/icons/hicolor/$size/apps" 2>/dev/null || true
                    cp "$icon_file" "/usr/share/icons/hicolor/$size/apps/" 2>/dev/null || {
                        echo "ERROR: Failed to copy $icon_file"
                    }
                    echo "  Installed icon: $(basename "$icon_file")"
                    icon_installed=true
                done
            fi

            # Check for individual icon files in root directory
            for icon_file in *.svg *.png; do
                if [ -f "$icon_file" ]; then
                    mkdir -p "/usr/share/icons/hicolor/scalable/apps" 2>/dev/null || true
                    cp "$icon_file" "/usr/share/icons/hicolor/scalable/apps/" 2>/dev/null || {
                        echo "ERROR: Failed to copy $icon_file"
                    }
                    echo "  Installed icon: $icon_file"
                    icon_installed=true
                fi
            done

            if [ "$icon_installed" = false ]; then
                echo "  No icons found"
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
