#!/usr/bin/env bash
set -euo pipefail

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "===$(basename "$0")==="
echo "::group:: Install COSMIC Applets"

# Install applets from pre-packaged artifacts
if [ -d "/applets" ] && [ "$(ls -A /applets)" ]; then
    echo "Installing applets from artifacts..."

    for applet_dir in /applets/*/; do
        if [ -d "$applet_dir" ]; then
            applet_name=$(basename "$applet_dir")
            echo "Installing applet: $applet_name"

            cd "$applet_dir"

            # Check for installation script
            if [ -f "install.sh" ]; then
                echo "Running install.sh for $applet_name"
                bash install.sh
            elif [ -f "justfile" ] && command -v just >/dev/null 2>&1 && just --list 2>/dev/null | grep -q "install"; then
                echo "Running just install for $applet_name"
                just install
            else
                echo "No installation script found, performing manual installation..."

                # Install binaries
                for binary in *cosmic*; do
                    if [ -f "$binary" ] && [ -x "$binary" ]; then
                        # Handle special naming cases
                        if [ "$applet_name" = "cosmic-ext-applet-emoji-selector" ]; then
                            install -Dm0755 "$binary" "/usr/bin/cosmic-applet-emoji-selector"
                            echo "Installed binary: cosmic-applet-emoji-selector (from $binary)"
                        else
                            install -Dm0755 "$binary" "/usr/bin/$binary"
                            echo "Installed binary: $binary"
                        fi
                    fi
                done

                # Install desktop files
                for desktop_file in *.desktop; do
                    if [ -f "$desktop_file" ]; then
                        install -Dm0644 "$desktop_file" "/usr/share/applications/$desktop_file"
                        echo "Installed desktop file: $desktop_file"
                    fi
                done

                # Install metainfo files
                for metainfo_file in *.metainfo.xml; do
                    if [ -f "$metainfo_file" ]; then
                        install -Dm0644 "$metainfo_file" "/usr/share/metainfo/$metainfo_file"
                        echo "Installed metainfo file: $metainfo_file"
                    fi
                done

                # Install icons (recursive)
                if [ -d "icons" ]; then
                    mkdir -p "/usr/share/icons/hicolor"
                    cp -r icons/* "/usr/share/icons/hicolor/"
                    echo "Installed icons from icons/ directory"
                fi

                # Install other common directories
                for dir in i18n-json schema; do
                    if [ -d "$dir" ]; then
                        mkdir -p "/usr/share/$applet_name/$dir"
                        cp -r "$dir"/* "/usr/share/$applet_name/$dir/" 2>/dev/null || true
                        echo "Installed $dir files"
                    fi
                done
            fi

            echo "Applet $applet_name installation completed"
            cd -
            echo ""
        fi
    done

    echo "All applets installed successfully"
else
    echo "No applet artifacts found, skipping applet installation"
fi

echo "::endgroup::"
