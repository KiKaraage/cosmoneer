# Build Scripts

This directory contains build scripts that run during image creation. Scripts are executed in numerical order.

## How It Works

Scripts are named with a number prefix (e.g., `00-base.sh`, `01-image-id.sh`) and run in ascending order during the container build process.

## Current Scripts

### Base System
- **`00-base.sh`** - Base system setup and core configuration
- **`01-image-id.sh`** - Image identification and metadata
- **`10-kernel-hardware.sh`** - Kernel and hardware support packages (currently disabled)
- **`11-packages.sh`** - System packages, CLI tools, and COPR packages
- **`20-desktop.sh`** - COSMIC desktop + Niri window manager installation
- **`21-applets.sh`** - COSMIC applets installation
- **`22-systemconf.sh`** - System files copying and service configuration

## Example Scripts

- **`onepassword.sh.example`** - Example showing how to install software from third-party RPM repositories

To use an example script:
1. Remove `.example` extension
2. Make it executable: `chmod +x build/20-yourscript.sh`
3. The build system will automatically run it in numerical order

## Creating Your Own Scripts

Create numbered scripts for different purposes following the existing pattern:

```bash
# 12-development.sh - Development tools
# 15-gaming.sh - Gaming software  
# 25-multimedia.sh - Multimedia packages
# 35-custom-services.sh - Custom service configurations
```

### Script Template

```bash
#!/usr/bin/bash
set -eoux pipefail

###############################################################################
# Script Purpose
###############################################################################
# Brief description of what this script does
###############################################################################

echo "::group:: Script Name"
# Your commands here
echo "::endgroup::"
```

### Best Practices

- **Use descriptive names**: `15-gaming.sh` is better than `15-stuff.sh`
- **One purpose per script**: Easier to debug and maintain
- **Clean up after yourself**: Remove temporary files and disable temporary repos
- **Test incrementally**: Add one script at a time and test builds
- **Comment your code**: Future you will thank present you
- **Use GitHub groups**: Wrap output in `echo "::group:: Name"` and `echo "::endgroup::"`

### Disabling Scripts

To temporarily disable a script without deleting it:
- Rename it with `.disabled` extension: `20-script.sh.disabled`
- Or remove execute permission: `chmod -x build/20-script.sh`

## Execution Order

The Containerfile runs scripts in this exact order:

```dockerfile
/ctx/build/00-base.sh && \
/ctx/build/01-image-id.sh && \
/ctx/build/10-kernel-hardware.sh && \
/ctx/build/11-packages.sh && \
/ctx/build/20-desktop.sh && \
/ctx/build/21-desktop-applets.sh && \
/ctx/build/22-systemconf.sh
```

## Notes

- Scripts run as root during build
- Build context is available at `/ctx`
- Use dnf5 for package management (not dnf or yum)
- Always use `-y` flag for non-interactive installs
- Services are configured globally but integrated with the COSMIC session
- Follow Zirconium's pattern: `systemctl enable --global` + `systemctl preset --global`
