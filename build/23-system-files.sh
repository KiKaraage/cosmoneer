#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# System Services & Configuration
###############################################################################
# This script configures essential system services for Cosmoneer
###############################################################################

echo "::group:: System Services Configuration"

echo "Configuring essential system services..."
# Enable core system services
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service

echo "::endgroup::"

# Configure bootc automatic updates
echo "Configuring automatic updates..."
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|^OnUnitInactiveSec=.*|OnUnitInactiveSec=7d\nPersistent=true|' /usr/lib/systemd/system/bootc-fetch-apply-updates.timer
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf
systemctl enable bootc-fetch-apply-updates

# Configure zram (compressed RAM)
echo "Configuring zram..."
tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
EOF

# Configure systemd-resolved as default
echo "Configuring systemd-resolved..."
tee /usr/lib/systemd/system-preset/91-resolved-default.preset <<'EOF'
enable systemd-resolved.service
EOF
tee /usr/lib/tmpfiles.d/resolved-default.conf <<'EOF'
L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf
EOF
systemctl preset systemd-resolved.service

# Enable firewalld
systemctl enable firewalld

echo "::group:: Container Registry Configuration"

# Add container registry configuration
echo "Configuring container registries..."
mkdir -p /etc/containers/registries.d
tee /etc/containers/registries.d/cosmoneer.yaml <<'EOF'
docker:
    io.github.ki.cosmoneer:
        tls: false
EOF

echo "::endgroup::"

echo "::group:: Portal Configuration"

# Configure xdg-desktop-portal for COSMIC on Niri
echo "Configuring portals for COSMIC on Niri session..."
mkdir -p /etc/xdg-desktop-portal
tee /etc/xdg-desktop-portal/cosmoneer-portals.conf <<'EOF'
[preferred]
default=cosmic
org.freedesktop.impl.portal.FileChooser=cosmic
org.freedesktop.impl.portal.Screenshot=cosmic
org.freedesktop.impl.portal.ScreenCast=cosmic
org.freedesktop.impl.portal.Settings=cosmic
EOF

# Update cosmic.portal to work with niri session
sed -i 's/UseIn=COSMIC/UseIn=COSMIC;niri/' /usr/share/xdg-desktop-portal/portals/cosmic.portal

echo "::endgroup::"

echo "::group:: Copy System Files"

# Copy system files to container
if [ -d "/ctx/system_files" ]; then
    echo "Copying system files..."
    rsync -rvK /ctx/system_files/ /
    echo "System files copied successfully"
else
    echo "No system_files directory found, skipping"
fi

echo "::endgroup::"

echo "::group:: Configure User Services"

# Uncomment PartOf=graphical-session.target for proper session integration
sed -i 's/# PartOf=graphical-session.target/PartOf=graphical-session.target/' "/usr/lib/systemd/user/cosmic-idle.service"

# Follow Zirconium's pattern: enable globally but ensure session integration
systemctl enable --global cosmic-idle.service
systemctl enable --global cosmic-ext-alternative-startup.service
systemctl enable --global cliphist.service
systemctl enable --global waybar.service

# Use preset to ensure proper configuration
systemctl preset --global cosmic-idle.service
systemctl preset --global cosmic-ext-alternative-startup.service
systemctl preset --global cliphist.service
systemctl preset --global waybar.service

echo "::endgroup::"

echo "::group:: System Configuration Files"

# Create sysusers.d configuration
echo "Creating sysusers.d configurations..."
mkdir -p /usr/lib/sysusers.d

# Create tmpfiles.d configuration
echo "Creating tmpfiles.d configurations..."
mkdir -p /usr/lib/tmpfiles.d

# Temporary directories for applications
# Note: %u template variables don't work in tmpfiles.d during container build
# These directories will be created dynamically at user session startup
tee /usr/lib/tmpfiles.d/cosmoneer.conf <<'EOF'
# Type Path Mode UID GID Age Argument
# User-specific temp directories - created at session startup
d /run/user/1000/tmp 0700 1000 1000 - -
d /run/user/1000/cliphist 0700 1000 1000 - -
EOF

echo "::endgroup::"

echo "System services and configuration completed successfully!"