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
    local repo_id
# Check if last argument is "priority"
    if [[ ${#packages[@]} -gt 0 && "${packages[-1]}" == "priority" ]]; then
        unset "packages[-1]"
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "ERROR: No packages specified for copr_install_isolated"
        return 1
    fi

    repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

    echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

    dnf5 -y copr enable "$copr_name"
    dnf5 -y copr disable "$copr_name"
    
    
    
    dnf5 -y install --enablerepo="$repo_id" "${packages[@]}" --skip-unavailable

    echo "Installed ${packages[*]} from $copr_name"
}
