#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# System Files Integration
###############################################################################
# This script copies system configuration files from system_files directory
###############################################################################

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

echo "System files integration complete!"