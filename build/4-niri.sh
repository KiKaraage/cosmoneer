#!/usr/bin/bash
set -eoux pipefail

echo "===$(basename "$0")==="
echo "::group:: Install Niri Window Manager"

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

copr_install_isolated "trixieua/morewaita-icon-theme" "morewaita-icon-theme"
copr_install_isolated "thrnciar/setuptools-78.1.1" "slurp"

# Install Niri from yalter/niri-git COPR directly
dnf5 -y copr enable yalter/niri-git
dnf5 -y copr disable yalter/niri-git
echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri-git.repo
dnf5 -y --enablerepo copr:copr.fedorainfracloud.org:yalter:niri-git install niri
rm -rf /usr/share/doc/niri
echo "Niri window manager installed successfully"

echo "::endgroup::"
