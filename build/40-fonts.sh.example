#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Install Additional Fonts
###############################################################################
# This script installs additional fonts for better desktop experience.
# Adapted from bluebuild fonts module (Apache-2.0 license)
# https://github.com/blue-build/modules/tree/main/modules/fonts
###############################################################################

echo "::group:: Install Additional Fonts from Fedora Repos"

# Install popular font packages from Fedora repos
dnf5 install -y \
    google-noto-emoji-fonts \
    fira-code-fonts \
    mozilla-fira-mono-fonts \
    mozilla-fira-sans-fonts \
    jetbrains-mono-fonts-all \
    fontawesome-fonts \
    fontawesome-fonts-web \
    curl \
    unzip

echo "Fedora font packages installed"
echo "::endgroup::"

echo "::group:: Install Google Fonts"

# Function to install Google Fonts
install_google_font() {
    local font_name="$1"
    local font_url="https://fonts.google.com/download?family=${font_name// /%20}"
    local font_dir="/usr/share/fonts/google-fonts/${font_name// /-}"
    
    echo "Installing Google Font: $font_name"
    mkdir -p "$font_dir"
    pushd /tmp >/dev/null
    curl -L "$font_url" -o "${font_name// /-}.zip"
    unzip -o "${font_name// /-}.zip" -d "$font_dir"
    # Clean up non-font files
    find "$font_dir" -type f ! \( -name "*.ttf" -o -name "*.otf" \) -delete
    rm -f "${font_name// /-}.zip"
    popd >/dev/null
}

# Add your Google Fonts here (examples provided)
# Uncomment to install additional Google Fonts:
# install_google_font "Roboto"
# install_google_font "Open Sans"
# install_google_font "Inter"

echo "Google Fonts installation complete"
echo "::endgroup::"

echo "::group:: Install Custom Fonts from URLs"

# Function to install fonts from custom URLs
install_custom_font() {
    local font_name="$1"
    local font_url="$2"
    local font_dir="/usr/share/fonts/custom-fonts/${font_name// /-}"
    
    echo "Installing Custom Font: $font_name from $font_url"
    mkdir -p "$font_dir"
    pushd /tmp >/dev/null
    
    # Get the file extension
    local filename
    filename=$(basename "$font_url")
    local extension="${filename##*.}"
    
    case "$extension" in
        ttf|otf)
            # Direct font file
            curl -L "$font_url" -o "$font_dir/$filename"
            ;;
        zip)
            # ZIP archive
            curl -L "$font_url" -o "${font_name// /-}.zip"
            unzip -o "${font_name// /-}.zip" -d "$font_dir"
            # Clean up non-font files
            find "$font_dir" -type f ! \( -name "*.ttf" -o -name "*.otf" \) -delete
            rm -f "${font_name// /-}.zip"
            ;;
        tar.gz|tgz)
            # Tar archive
            curl -L "$font_url" -o "${font_name// /-}.tar.gz"
            tar -xzf "${font_name// /-}.tar.gz" -C "$font_dir"
            # Clean up non-font files
            find "$font_dir" -type f ! \( -name "*.ttf" -o -name "*.otf" \) -delete
            rm -f "${font_name// /-}.tar.gz"
            ;;
        *)
            echo "Warning: Unknown file extension for $font_url, skipping"
            ;;
    esac

    popd >/dev/null
}

# Add your custom font URLs here (examples provided)
# Uncomment to install custom fonts:
# install_custom_font "CustomFont" "https://example.com/my-font.otf"
# install_custom_font "CompanyFonts" "https://company.com/fonts.zip"

echo "Custom fonts installation complete"
echo "::endgroup::"

echo "::group:: Update Font Cache"

# Update font cache
fc-cache -f

echo "Font cache updated"
echo "::endgroup::"

echo "Font installation complete!"
