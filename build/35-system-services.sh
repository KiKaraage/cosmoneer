#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# System Services & Configuration
###############################################################################
# This script configures essential system services from bluefin and zirconium
###############################################################################

echo "::group:: System Services Configuration"

echo "Configuring essential system services..."
# Enable core system services
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service

echo "::endgroup::"

# Configure bootc automatic updates (from bluefin)
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

# Add container registry configuration (from zirconium)
echo "Configuring container registries..."
mkdir -p /etc/containers/registries.d
tee /etc/containers/registries.d/cosmoneer.yaml <<'EOF'
docker:
    io.github.ki.cosmoneer:
        tls: false
EOF

echo "::endgroup::"

echo "::group:: Systemd User Services"

# Configure user services for cliphist and session management
echo "Configuring user services..."

# Create cliphist service
tee /usr/lib/systemd/user/cliphist.service <<'EOF'
[Unit]
Description=Clipboard history service
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/cliphist watch
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo "::group:: Configure Niri Services"

# Fix cosmic-idle.service to uncomment PartOf=graphical-session.target
sed -i 's/# PartOf=graphical-session.target/PartOf=graphical-session.target/' "/usr/lib/systemd/user/cosmic-idle.service"

# Enable the services globally so they start with the cosmic session
systemctl enable --global cosmic-idle.service
systemctl enable --global cosmic-ext-alternative-startup.service
systemctl enable --global waybar.service

echo "Niri services configured for cosmic-session"
echo "::endgroup::"

# Enable user services
systemctl enable --global cliphist.service

echo "::endgroup::"

echo "::group:: System Configuration Files"

# Create sysusers.d configuration
echo "Creating sysusers.d configurations..."
mkdir -p /usr/lib/sysusers.d

# Docker group (already created in 30-system-packages.sh, but ensuring it's here)
tee /usr/lib/sysusers.d/docker.conf <<'EOF'
g docker -
EOF

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