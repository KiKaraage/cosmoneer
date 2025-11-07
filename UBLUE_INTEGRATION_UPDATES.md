# Cosmoneer ublue Integration Updates

## Changes Made

### 1. Enhanced Package Management (30-system-packages.sh)
- **Separated Fedora vs COPR packages** following bluefin security pattern
- **Added package exclusion list** to remove unwanted default packages
- **Added brightnessctl** (Fedora package) for brightness control
- **Added chezmoi** for dotfile management
- **Added ublue-os-udev-rules** for hardware device management
- **Added cliphist** from zirconium COPR for clipboard history

### 2. New System Services Script (35-system-services.sh)
- **Bluefin services:**
  - Automatic updates configuration (bootc-fetch-apply-updates)
  - zram configuration for compressed RAM
  - systemd-resolved as default DNS resolver
- **Zirconium services:**
  - cliphist user service for clipboard history
  - swayidle service for session idle management
- **Container registry configuration** for Cosmoneer

### 3. System Files Integration (25-system-files.sh)
- Created framework for system-wide configuration files
- Added sysusers.d and tmpfiles.d configurations
- Prepared structure for future system configurations

## Package Explanations

### ublue-os-udev-rules
- **Purpose:** Hardware device management rules
- **Covers:** 
  - Framework laptop suspend/resume fixes
  - Graphics tablet support (Wacom, etc.)
  - Input device permissions
  - Container device access rules
- **Does NOT cover:** Docker (has its own udev rules)

### brightnessctl
- **Source:** Fedora repositories
- **Purpose:** Brightness control for laptops
- **Integration:** Works with both Cosmic and Niri

### cliphist
- **Source:** zirconium/packages COPR
- **Purpose:** Clipboard history management
- **Service:** User-level systemd service
- **Integration:** Essential for Wayland sessions

### chezmoi
- **Source:** Fedora repositories  
- **Purpose:** Dotfile management system
- **Benefits:** Better than manual dotfile management

## Security Improvements

1. **Package Separation:** Fedora packages installed in bulk, COPR packages isolated
2. **Package Exclusions:** Removes unwanted default packages
3. **Proper Service Management:** User services properly integrated
4. **System Configuration:** tmpfiles.d and sysusers.d for security

## Next Steps

1. Test the build with new structure
2. Verify cliphist installation from zirconium COPR
3. Test brightness control functionality
4. Verify system services are working correctly
5. Test automatic updates configuration