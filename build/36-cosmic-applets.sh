#!/usr/bin/env bash
set -euo pipefail

echo "::group:: Install COSMIC Applets"

# Install applets from artifacts if they exist
if [ -d "/applets" ] && [ "$(ls -A /applets)" ]; then
    echo "Installing applets from artifacts..."
    
    # Extract ZIP files if present
    for zip_file in /applets/*.zip; do
        if [ -f "$zip_file" ]; then
            applet_name=$(basename "$zip_file" .zip)
            echo "Extracting $applet_name..."
            # Convert underscores back to hyphens for directory naming consistency
            applet_dir_name=$(echo "$applet_name" | sed 's/_/-/g')
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
            echo "Searching for binary: $expected_binary_name in target/release/..."
            binary=$(find . -path "*/target/release/*" -name "$expected_binary_name" -type f -executable | head -1)
            
            if [ -z "$binary" ]; then
                echo "Not found in target/release/, trying justfile name variable..."
                # Try to find from justfile name variable
                if [ -f "justfile" ]; then
                    echo "Justfile contents (first 10 lines):"
                    head -10 justfile | sed 's/^/  /' || true
                    echo ""
                    justfile_name=$(grep "^name :=" justfile | sed "s/name := '//" | sed "s/'//")
                    if [ -n "$justfile_name" ]; then
                        echo "Found justfile name: $justfile_name"
                        binary=$(find . -path "*/target/release/*" -name "$justfile_name" -type f -executable | head -1)
                    else
                        echo "No name variable found in justfile with pattern '^name :='"
                        # Try alternative patterns
                        justfile_name=$(grep "^name\s*=" justfile | sed 's/^name\s*=\s*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//')
                        if [ -n "$justfile_name" ]; then
                            echo "Found justfile name with alternative pattern: $justfile_name"
                            binary=$(find . -path "*/target/release/*" -name "$justfile_name" -type f -executable | head -1)
                        fi
                    fi
                else
                    echo "No justfile found"
                fi
            fi
            
            if [ -z "$binary" ]; then
                echo "Not found with justfile name, trying generic cosmic search in target/release..."
                # Fallback to generic cosmic search in target/release
                binary=$(find . -path "*/target/release/*" -name "cosmic*" -type f -executable | head -1)
            fi
            
            if [ -z "$binary" ]; then
                echo "Not found in target/release/, searching root directory for $expected_binary_name..."
                # Final fallback to root directory search with expected binary name
                binary=$(find . -maxdepth 2 -name "$expected_binary_name" -type f -executable | head -1)
            fi
            
            if [ -z "$binary" ]; then
                echo "Not found with expected name, searching root directory for any cosmic binary..."
                # Final fallback to root directory search with generic cosmic pattern
                binary=$(find . -maxdepth 2 -name "cosmic*" -type f -executable | head -1)
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
                
                # Install desktop files from their original locations
                desktop_files=$(find . -name "*.desktop" -type f)
                if [ -n "$desktop_files" ]; then
                    echo "Installing desktop files..."
                    echo "$desktop_files" | while read -r desktop_file; do
                        install -Dm0644 "$desktop_file" "/usr/share/applications/$(basename "$desktop_file")"
                        echo "  Installed desktop file: $(basename "$desktop_file")"
                    done
                fi
                
                # Install metainfo files from their original locations
                metainfo_files=$(find . -name "*.metainfo.xml" -type f)
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