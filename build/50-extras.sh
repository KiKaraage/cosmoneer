#!/usr/bin/env bash

set -xeuo pipefail

###############################################################################
# Install Docker CE and related extras
###############################################################################

echo "::group:: Install & Configure Docker CE"

# Add Docker repository and enable when installing
dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 -y install --enablerepo='docker-ce-stable' docker-ce docker-ce-cli docker-compose-plugin

# Enable ssh-agent for all users
systemctl enable --global ssh-agent

# Create docker-compose symlink
ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Ensure sysctl configuration exists
mkdir -p /usr/lib/sysctl.d
echo "net.ipv4.ip_forward = 1" >/usr/lib/sysctl.d/docker-ce.conf

# Disable Docker by default in system preset and then preset to ensure proper state
sed -i 's/enable docker/disable docker/' /usr/lib/systemd/system-preset/90-default.preset
systemctl preset docker.service docker.socket

# Create docker group configuration
cat >/usr/lib/sysusers.d/docker.conf <<'EOF'
g docker -
EOF

echo "Docker installation and configuration complete!"
echo "::endgroup::"