#!/usr/bin/bash

set -eoux pipefail

# System Services & Configuration
# This script configures essential system services for Cosmoneer
# 1. Docker CE
# 2. Tailscale
# 3.
echo "===$(basename "$0")==="

echo "::group:: Docker CE"

echo "Installing Docker CE..."
dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --skip-unavailable --enablerepo='docker-ce-stable' docker-ce docker-ce-cli docker-compose-plugin

echo "Configuring Docker CE..."
# Enable SSH agent globally
systemctl enable --global ssh-agent

# Create docker-compose symlink
ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Enable IP forwarding for Docker
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" > /usr/lib/sysctl.d/docker-ce.conf

# Configure Docker service presets
sed -i 's/enable docker/disable docker/' /usr/lib/systemd/system-preset/90-default.preset
systemctl preset docker.service docker.socket

# Create docker group
cat > /usr/lib/sysusers.d/docker.conf <<'EOF'
g docker -
EOF

echo "::endgroup::"

echo "Enable Tailscale daemon service"
systemctl enable tailscaled || echo "Can't enable Tailscale daemon service"

echo "::group:: System Services Configuration"

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

# Essential tmpfiles.d entries
tee /usr/lib/tmpfiles.d/cosmoneer.conf <<'EOF'
# Type Path Mode UID GID Age Argument
# Essential system directories that aren't created by packages
L /var/lib/greetd/.config/systemd/user/xdg-desktop-portal.service - - - - /dev/null
d /var/lib/AccountsService 0775 root root - -
d /var/lib/AccountsService/icons 0775 root root - -
d /var/lib/AccountsService/users 0700 root root - -
EOF

echo "::endgroup::"
