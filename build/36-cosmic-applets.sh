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
                mv "$nested_dir" "/applets/"
            else
                echo "No nested directory found, moving all contents..."
                mkdir -p "/applets/$applet_name"
                mv "$temp_dir"/* "/applets/$applet_name/"
            fi
            rmdir "$temp_dir"
            rm "$zip_file"  # Remove ZIP after extraction
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
            
            # Install binary if present (in target/release/ or root)
            binary=$(find . -path "*/target/release/*" -name "cosmic*" -type f -executable | head -1)
            if [ -z "$binary" ]; then
                binary=$(find . -maxdepth 2 -name "cosmic*" -type f -executable | head -1)
            fi
            if [ -n "$binary" ]; then
                binary_name=$(basename "$binary")
                install -Dm0755 "$binary" "/usr/bin/$binary_name"
                echo "Installed binary: $binary_name"
            fi
            
            # Run just install if justfile exists and has install target AND binary exists
            if [ -f "justfile" ] && just --list 2>/dev/null | grep -q "install" && [ -n "$binary" ]; then
                echo "Running just install for $applet_name"
                just install
            elif [ -f "install.sh" ]; then
                echo "Running install.sh for $applet_name"
                bash install.sh
            else
                echo "No justfile install target or install.sh found, performing manual installation..."
                
                # Manual installation based on preserved structure
                
                # Install desktop files from their original locations
                find . -name "*.desktop" -type f | while read -r desktop_file; do
                    install -Dm0644 "$desktop_file" "/usr/share/applications/$(basename "$desktop_file")"
                    echo "Installed desktop file: $(basename "$desktop_file")"
                done
                
                # Install metainfo files from their original locations
                find . -name "*.metainfo.xml" -type f | while read -r metainfo_file; do
                    install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$(basename "$metainfo_file")"
                    echo "Installed metainfo file: $(basename "$metainfo_file")"
                done
                
                # Install icons from their original structure
                if [ -d "res/icons" ]; then
                    find res/icons -type f | while read -r icon_file; do
                        relative_path="${icon_file#res/icons/}"
                        install -Dm0644 "$icon_file" "/usr/share/icons/hicolor/$relative_path"
                        echo "Installed icon: $relative_path"
                    done
                elif [ -d "data/icons" ]; then
                    find data/icons -type f | while read -r icon_file; do
                        relative_path="${icon_file#data/icons/}"
                        install -Dm0644 "$icon_file" "/usr/share/icons/hicolor/$relative_path"
                        echo "Installed icon: $relative_path"
                    done
                fi
                
                # Install i18n files from their original structure
                if [ -d "i18n-json" ]; then
                    find i18n-json -type f | while read -r i18n_file; do
                        relative_path="${i18n_file#i18n-json/}"
                        install -Dm0644 "$i18n_file" "/usr/share/$applet_name/i18n-json/$relative_path"
                        echo "Installed i18n file: $relative_path"
                    done
                fi
                
                # Install schema files if present
                if [ -d "data/schema" ]; then
                    find data/schema -type f | while read -r schema_file; do
                        relative_path="${schema_file#data/schema/}"
                        install -Dm0644 "$schema_file" "/usr/share/$applet_name/schema/$relative_path"
                        echo "Installed schema file: $relative_path"
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