#!/usr/bin/env bash
set -euo pipefail

echo "===$(basename "$0")==="
echo "::group:: COSMIC Applets Artifacts"
echo "Running in directory: $(pwd)"
echo "Starting applet installation process..."

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
    echo "Processing loose files in /applets..."
    for filename in "${!file_to_applet[@]}"; do
        applet_dir="${file_to_applet[$filename]}"
        if [ -f "/applets/$filename" ]; then
            mkdir -p "/applets/$applet_dir"
            echo "Moving $filename to $applet_dir/"
            mv "/applets/$filename" "/applets/$applet_dir/"
        fi
    done
    echo "Loose files processed"

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
    echo "Checking for ZIP files in /applets..."
    ls -la /applets/*.zip 2>/dev/null || echo "No ZIP files found"
    for zip_file in /applets/*.zip; do
        if [ -f "$zip_file" ]; then
            applet_name=$(basename "$zip_file" .zip)
            echo "=== Extracting $applet_name from $(basename "$zip_file") ==="
            echo "ZIP file information:"
            unzip -l "$zip_file" | head -20 || true

            # Extract applets to temp dir
            applet_dir_name=${applet_name//_/-}
            temp_dir="/tmp/$applet_name"
            mkdir -p "$temp_dir"
            echo "Unzipping to $temp_dir..."
            unzip -q "$zip_file" -d "$temp_dir"
            echo "Extracted directory structure:"
            find "$temp_dir" -type d | head -10 || true
            echo "Extracted files:"
            find "$temp_dir" -type f | head -10 || true

            # Handle nested directory structure
            nested_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
            echo "Checking for nested directory structure..."
            echo "Top-level entries in temp_dir:"
            find "$temp_dir" -mindepth 1 -maxdepth 1 -exec ls -la {} \; || true
            echo "Number of top-level entries: $(find "$temp_dir" -mindepth 1 -maxdepth 1 | wc -l)"

            if [ -n "$nested_dir" ] && [ "$(find "$temp_dir" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
                echo "Found single nested directory: $nested_dir"
                echo "Moving contents from nested directory to /applets/$applet_dir_name/..."
                mkdir -p "/applets/$applet_dir_name"
                cp -r "$nested_dir"/* "/applets/$applet_dir_name/" 2>/dev/null || true
                echo "Copied directory structure from nested directory"
                echo "Resulting contents in /applets/$applet_dir_name:"
                find "/applets/$applet_dir_name" -type f | head -10 || true
            else
                echo "No nested directory found, moving all contents..."
                mkdir -p "/applets/$applet_dir_name"
                cp -r "$temp_dir"/* "/applets/$applet_dir_name/" 2>/dev/null || true
                echo "Copied all contents from temp directory"
                echo "Resulting contents in /applets/$applet_dir_name:"
                find "/applets/$applet_dir_name" -type f | head -10 || true
            fi
            rmdir "$temp_dir"
            rm "$zip_file"

            # Log extracted contents
            echo "Extracted files for $applet_name:"
            if [ -d "/applets/$applet_dir_name" ]; then
                echo "  Full directory structure:"
                find "/applets/$applet_dir_name" -type f | head -20 || true
                echo "  Directory listing:"
                ls -la "/applets/$applet_dir_name" || true

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
                # List contents of subdirectories
                if [ -d "/applets/$applet_dir_name/$(basename "$dir")" ]; then
                    echo "    Contents of $(basename "$dir"):"
                    find "/applets/$applet_dir_name/$(basename "$dir")" -type f | head -10 || true
                fi
            done
            fi
        fi
    done

    # Define valid applet names to avoid processing non-applet directories
    VALID_APPLETS="cosmic-ext-applet-emoji-selector cosmic-ext-applet-privacy-indicator cosmic-ext-applet-vitals cosmic-ext-applet-caffeine cosmic-ext-applet-clipboard-manager cosmic-ext-alternative-startup wf-recorder-gui cosmic-ext-bg-theme"

    echo "Processing applet directories in /applets/..."
    for applet_dir in /applets/*/; do
        if [ -d "$applet_dir" ]; then
            applet_name=$(basename "$applet_dir")
            # Skip directories that are not valid applets
            if ! echo "$VALID_APPLETS" | grep -q -w "$applet_name"; then
                echo "Skipping non-applet directory: $applet_name"
                continue
            fi
            echo "Installing applet: $applet_name"
            cd "$applet_dir" || { echo "ERROR: Failed to change to directory $applet_dir"; continue; }

            echo "Current directory contents:"
            echo "Full directory listing:"
            find . -type f | head -20 || true
            echo "Top-level directory structure:"
            ls -la || true
            echo "Subdirectory contents:"
            for d in */; do
                if [ -d "$d" ]; then
                    echo "Directory: $d"
                    find "$d" -type f | head -10 || true
                fi
            done

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
            expected_binaries=$(yq eval ".{$SECTION}[\"$applet_name\"].binary_names[]" applets.yml 2>/dev/null || echo "")

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

            # Desktop files (recursive search in all directories)
            desktop_count=0
            # Find all .desktop files recursively
            echo "  Searching for desktop files..."
            find . -name "*.desktop" -type f | while read -r desktop_file; do
                echo "  Found desktop file: $desktop_file"
                filename=$(basename "$desktop_file")

                # Special case for clipboard manager desktop file - rename to match applet name
                if [[ "$applet_name" == "cosmic-ext-applet-clipboard-manager" ]] && [[ "$filename" == "desktop_entry.desktop" ]]; then
                    install -Dm0644 "$desktop_file" "/usr/share/applications/io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager.desktop" || {
                        echo "ERROR: Failed to install desktop file: $desktop_file"
                    }
                    echo "  Installed desktop file: io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager.desktop (renamed from $filename)"
                else
                    install -Dm0644 "$desktop_file" "/usr/share/applications/$filename" || {
                        echo "ERROR: Failed to install desktop file: $desktop_file"
                    }
                    echo "  Installed desktop file: $filename"
                fi
                desktop_count=$((desktop_count + 1))
            done
            if [ $desktop_count -eq 0 ]; then
                echo "  No desktop files found"
            fi

            # Metainfo files (recursive search in all directories)
            metainfo_count=0
            # Find all .metainfo.xml files recursively
            echo "  Searching for metainfo files..."
            find . -name "*.metainfo.xml" -type f | while read -r metainfo_file; do
                echo "  Found metainfo file: $metainfo_file"
                filename=$(basename "$metainfo_file")

                # Special case for clipboard manager metainfo file - rename to match applet name
                if [[ "$applet_name" == "cosmic-ext-applet-clipboard-manager" ]] && [[ "$filename" == "metainfo.xml" ]]; then
                    install -Dm0644 "$metainfo_file" "/usr/share/metainfo/io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager.metainfo.xml" || {
                        echo "ERROR: Failed to install metainfo file: $metainfo_file"
                    }
                    echo "  Installed metainfo file: io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager.metainfo.xml (renamed from $filename)"
                else
                    install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$filename" || {
                        echo "ERROR: Failed to install metainfo file: $metainfo_file"
                    }
                    echo "  Installed metainfo file: $filename"
                fi
                metainfo_count=$((metainfo_count + 1))
            done
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
                echo "  Found res directory, processing icons..."
                mkdir -p "/usr/share/icons/hicolor" || {
                    echo "ERROR: Failed to create icons directory"
                }
                # Copy SVG and PNG files from res directory recursively
                find res -name "*.svg" -o -name "*.png" | while read -r icon_file; do
                    # Determine icon size from filename or use scalable
                    if [[ "$icon_file" =~ ([0-9]+)x[0-9]+ ]]; then
                        size="${BASH_REMATCH[1]}x${BASH_REMATCH[1]}"
                    else
                        size="scalable"
                    fi
                    mkdir -p "/usr/share/icons/hicolor/$size/apps" 2>/dev/null || true

                    # Handle special case for app_icon.svg - rename to match desktop entry expectation
                    icon_dest_name="$(basename "$icon_file")"
                    if [[ "$icon_file" == *"app_icon.svg" ]] && [[ "$applet_name" == "cosmic-ext-applet-clipboard-manager" ]]; then
                        # Desktop entry expects: io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager-symbolic
                        icon_dest_name="io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager-symbolic.svg"
                        echo "  Special case: Renaming app_icon.svg to match desktop entry expectation"
                    fi

                    cp "$icon_file" "/usr/share/icons/hicolor/$size/apps/$icon_dest_name" 2>/dev/null || {
                        echo "ERROR: Failed to copy $icon_file"
                    }
                    echo "  Installed icon: $icon_dest_name"
                    icon_installed=true
                done
            else
                echo "  No res directory found"
            fi

            # Check for individual icon files in root directory
            echo "  Checking for individual icon files in root directory..."
            for icon_file in *.svg *.png; do
                if [ -f "$icon_file" ]; then
                    echo "  Found icon file in root: $icon_file"
                    mkdir -p "/usr/share/icons/hicolor/scalable/apps" 2>/dev/null || true
                    cp "$icon_file" "/usr/share/icons/hicolor/scalable/apps/" 2>/dev/null || {
                        echo "ERROR: Failed to copy $icon_file"
                    }
                    echo "  Installed icon: $icon_file"
                    icon_installed=true
                fi
            done

            if [ "$icon_installed" = false ]; then
                echo "  No icons found anywhere"
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
            cd - > /dev/null || echo "WARNING: Failed to return to previous directory"
        fi
    done

    echo "All applets installed successfully"
else
    echo "No applet artifacts found, skipping applet installation"
    exit 0
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
