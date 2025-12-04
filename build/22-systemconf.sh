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

echo "Configuring container registries..."
mkdir -p /etc/containers/registries.d
tee /etc/containers/registries.d/cosmoneer.yaml <<'EOF'
docker:
    io.github.ki.cosmoneer:
        tls: false
EOF

echo "Copy system files to container..."
if [ -d "/ctx/system_files" ]; then
    rsync -rvK /ctx/system_files/ /
fi

echo "::endgroup::"


echo "::group:: Configure User Services"

# Unmask cosmic-niri-session, then apply user service presets from system_files
systemctl unmask --global cosmic-niri-session.service 2>/dev/null || true
systemctl preset-all --global || true

# Configure Niri session services using dynamic wants configs
add_wants_niri() {
    sed -i "s|\[Unit\]|\[Unit\]\nWants=$1|" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri cliphist.service
add_wants_niri swayidle.service
add_wants_niri udiskie.service
add_wants_niri cosmic-notifications.service

# Replace complex symlink logic with preset pattern
cat > /usr/lib/systemd/user-preset/01-cosmoneer.preset <<'EOF'
enable swayidle.service
enable cliphist.service
enable cosmic-niri-session.service
enable gnome-keyring-daemon.socket
enable cosmic-notifications.service
EOF

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
