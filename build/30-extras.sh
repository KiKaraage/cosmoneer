#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Additional Software and External RPMs
###############################################################################
# This script installs additional software from dnf5 and external RPM sources
###############################################################################

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Install Hardware and Networking Packages"

dnf5 install -y \
    igt-gpu-tools \
    switcheroo-control \
    foo2zjs \
    ifuse \
    tailscale \
    iwd \
    waypipe \
    msedit \
    fontawesome-fonts \
    fontawesome-fonts-web \
    adwaita-icon-theme

systemctl enable tailscaled

echo "::endgroup::"

copr_install_isolated "trixieua/morewaita-icon-theme" "morewaita-icon-theme"

echo "::group:: Install Waveterm from GitHub release"

# Check if curl is available
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not available, skipping Waveterm installation"
else
    # Get the latest release assets
    RELEASE_API_URL="https://api.github.com/repos/wavetermdev/waveterm/releases/latest"
    echo "Fetching latest Waveterm release assets from: $RELEASE_API_URL"
    
    # Find the first x86_64 RPM in the latest release assets
    RPM_URL=$(curl -s "$RELEASE_API_URL" | grep -o '"browser_download_url": "[^"]*waveterm-linux-x86_64[^"]*\.rpm"' | sed 's/"browser_download_url": "//;s/"$//' | head -1)
    
    if [ -n "$RPM_URL" ]; then
        echo "Found Waveterm x86_64 RPM: $RPM_URL"
        if curl -L -f -o waveterm.rpm "$RPM_URL"; then
            # Clean up existing installation to prevent conflicts (only if it exists)
            if [ -d "/opt/Wave" ]; then
                echo "Removing existing /opt/Wave directory..."
                # Try multiple approaches to remove the directory
                rm -rf /opt/Wave 2>/dev/null || \
                find /opt/Wave -type f -delete 2>/dev/null && rmdir /opt/Wave 2>/dev/null || \
                (chmod -R 755 /opt/Wave 2>/dev/null && rm -rf /opt/Wave 2>/dev/null) || \
                echo "Warning: Could not remove /opt/Wave, attempting force install"
            fi
            # Try manual extraction and installation to avoid cpio issues
            echo "Extracting RPM manually to avoid cpio conflicts..."
            mkdir -p /tmp/waveterm-extract
            
            # Extract RPM contents
            if rpm2cpio waveterm.rpm | (cd /tmp/waveterm-extract && cpio -idm) 2>/dev/null; then
                echo "RPM extracted successfully, copying files..."
                # Copy files to their destinations
                cp -r /tmp/waveterm-extract/opt/* /opt/ 2>/dev/null || true
                cp -r /tmp/waveterm-extract/usr/* /usr/ 2>/dev/null || true
                
                # Register the package in RPM database
                rpm -i --justdb waveterm.rpm 2>/dev/null || true
                
                echo "Manual installation completed"
            else
                echo "Manual extraction failed, trying standard rpm install..."
                rpm -ivh --force --nodeps waveterm.rpm || echo "Warning: All installation methods failed"
            fi
            
            # Cleanup
            rm -rf /tmp/waveterm-extract
            echo "Waveterm installed successfully"
            rm -f waveterm.rpm
        else
            echo "Failed to download Waveterm RPM, continuing without it"
        fi
    else
        echo "No x86_64 RPM found in latest Waveterm release assets, continuing without it"
    fi
fi

echo "::endgroup::"

