#!/usr/bin/bash
set -euo pipefail

###############################################################################
# COPR Helper Functions
###############################################################################
# These helper functions follow the @ublue-os/bluefin pattern for managing
# COPR repositories in a safe, isolated manner.
###############################################################################

copr_install_isolated() {
    local copr_name="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "ERROR: No packages specified for copr_install_isolated"
        return 1
    fi

    repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

    echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

    dnf5 -y copr enable "$copr_name"
    dnf5 -y copr disable "$copr_name"
    
    # Ensure the repo file has proper format before adding priority
    if [[ -f "/etc/yum.repos.d/_copr:${repo_id}.repo" ]]; then
        # Add priority setting to the end of the file with proper formatting
        echo -e "\n[${repo_id}]\npriority=1" >> "/etc/yum.repos.d/_copr:${repo_id}.repo"
    fi
    
    dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"

    echo "Installed ${packages[*]} from $copr_name"
}
