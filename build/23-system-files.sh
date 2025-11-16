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

echo "::endgroup::"
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

# Configure xdg-desktop-portal for Niri with COSMIC as primary
echo "Configuring portals for Niri session..."
mkdir -p /etc/xdg-desktop-portal
tee /etc/xdg-desktop-portal/cosmoneer-portals.conf <<'EOF'
[preferred]
default=cosmic;gnome;
org.freedesktop.impl.portal.Access=cosmic;gnome;
org.freedesktop.impl.portal.Notification=cosmic;gnome;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=cosmic;gnome;
org.freedesktop.impl.portal.Screenshot=cosmic;gnome;
org.freedesktop.impl.portal.Inhibit=cosmic;gnome;
org.freedesktop.impl.portal.Background=cosmic;gnome;
EOF

echo "::endgroup::"
echo "::group:: Copy System Files"

# Copy system files to container
if [ -d "/ctx/system_files" ]; then
    rsync -rvK /ctx/system_files/ /
    # Make the COSMIC portal wrapper executable
    if [ -f "/usr/libexec/xdg-desktop-portal-cosmic-wrapper" ]; then
        chmod +x /usr/libexec/xdg-desktop-portal-cosmic-wrapper
    fi
fi

echo "::endgroup::"
echo "::group:: Configure User Services"

# Unmask any previously masked services to allow presets
systemctl unmask --global cosmic-idle.service 2>/dev/null || true
systemctl unmask --global cosmic-ext-alternative-startup.service 2>/dev/null || true
systemctl unmask --global cosmic-ext-bg-theme.service 2>/dev/null || true

# Apply user service presets from system_files
systemctl preset-all --global || true

# Configure Niri session services (waybar and cliphist)
mkdir -p /usr/lib/systemd/user/niri.service.wants
if [ -f /usr/lib/systemd/user/waybar.service ]; then
    ln -sf /usr/lib/systemd/user/waybar.service /usr/lib/systemd/user/niri.service.wants/waybar.service
fi
if [ -f /usr/lib/systemd/user/cliphist.service ]; then
    ln -sf /usr/lib/systemd/user/cliphist.service /usr/lib/systemd/user/niri.service.wants/cliphist.service
fi

echo "::endgroup::"

echo "::group:: System Configuration Files"

# Create sysusers.d and tmpfiles.d directories
mkdir -p /usr/lib/sysusers.d
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