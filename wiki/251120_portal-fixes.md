# Portal Configuration and Filepicker Fixes - November 20, 2025

## Issue Summary
COSMIC on Niri hybrid desktop environment had portal service failures causing filepicker issues in native GTK applications, while Flatpak applications worked correctly.

## Root Causes Identified

### 1. Missing Display Environment Variables
Portal services (xdg-desktop-portal-cosmic, xdg-desktop-portal-gtk) failed to start due to missing `WAYLAND_DISPLAY` and `DISPLAY` environment variables in systemd user session.

### 2. COSMIC Portal Crashes in Hybrid Environment
The COSMIC portal implementation crashed with Rust panic when running in Niri+COSMIC hybrid setup, expecting full COSMIC desktop environment.

### 3. GTK Applications Not Using Portals
Native GTK applications were using built-in file chooser dialogs instead of portal system, causing inconsistent behavior.

## Fixes Applied

### 1. Environment Import Service
Created `system_files/usr/lib/systemd/user/display-environment.service` to handle environment import and portal restart after compositor startup:

```ini
[Unit]
Description=Import display environment and restart portals
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
    # Wait for Wayland display and import environment
    timeout=30
    while [ $timeout -gt 0 ]; do
        if [ -n "$WAYLAND_DISPLAY" ] && [ -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
            systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP 2>/dev/null || true
            systemctl --user restart xdg-desktop-portal-gtk.service 2>/dev/null || true
            systemctl --user restart xdg-desktop-portal-cosmic.service 2>/dev/null || true
            exit 0
        fi
        sleep 0.1
        timeout=$((timeout - 1))
    done
    exit 1
'
```

Added to `system_files/usr/lib/systemd/user-preset/01-cosmoneer.preset` to enable automatically.

### 2. Portal Service Environment Variables
Added `XDG_SESSION_TYPE=wayland` to portal service files:
- `system_files/usr/lib/systemd/user/xdg-desktop-portal-cosmic.service`
- `system_files/usr/lib/systemd/user/xdg-desktop-portal-gtk.service`

### 3. GTK Portal Usage Enforcement
Added `GTK_USE_PORTAL=1` to session environment in `start-cosmic-ext-niri` to force GTK applications to use portal system.

### 4. Portal Configuration Optimization
Modified `system_files/usr/share/xdg-desktop-portal/niri-portals.conf` to prefer GNOME for FileChooser (since nautilus is available):

```ini
[preferred]
default=gnome;cosmic;
org.freedesktop.impl.portal.Access=cosmic;gnome;
org.freedesktop.impl.portal.Notification=cosmic;gnome;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gnome;cosmic;  # Changed to prefer GNOME over GTK
org.freedesktop.impl.portal.Screenshot=cosmic;gnome;
org.freedesktop.impl.portal.Inhibit=cosmic;gnome;
org.freedesktop.impl.portal.Background=cosmic;gnome;
```

### 5. COSMIC Service Environment Cleanup
Removed hardcoded `WAYLAND_DISPLAY` and `DISPLAY` from COSMIC service files, allowing them to inherit environment from session:
- `system_files/usr/lib/systemd/user/cosmic-ext-alternative-startup.service`
- `system_files/usr/lib/systemd/user/cosmic-idle.service`
- `system_files/usr/lib/systemd/user/cosmic-ext-bg-theme.service`
- `system_files/usr/lib/systemd/user/waybar.service`

## Current Status

### Working
- Flatpak applications use COSMIC portal successfully
- Native GTK applications now use GTK portal for file choosers
- COSMIC services start without crashes
- Session initialization completes successfully

### Known Issues
- COSMIC portal crashes in hybrid environment (expected, using GTK fallback for file chooser)
- Portal services may need manual restart if environment import fails during startup

## Testing Recommendations

1. **Filepicker Testing**: Open file dialogs in both native GTK apps (gedit, etc.) and Flatpak apps
2. **Portal Logs**: Monitor with `journalctl --user -u xdg-desktop-portal -f`
3. **Service Status**: Check `systemctl --user status xdg-desktop-portal*`
4. **Environment Service**: Verify `systemctl --user status display-environment.service` runs successfully

## Future Improvements

1. **Environment Import Timing**: Ensure display variables are imported before any portal services start
2. **COSMIC Portal Compatibility**: Investigate making COSMIC portal work in hybrid environments
3. **Portal Fallback Logic**: Implement smarter fallback when preferred portal fails

## Files Modified
- `system_files/usr/bin/start-cosmic-ext-niri`
- `system_files/usr/lib/systemd/user/xdg-desktop-portal-cosmic.service`
- `system_files/usr/lib/systemd/user/xdg-desktop-portal-gtk.service`
- `system_files/usr/share/xdg-desktop-portal/niri-portals.conf`
- `system_files/usr/lib/systemd/user/cosmic-ext-alternative-startup.service`
- `system_files/usr/lib/systemd/user/cosmic-idle.service`
- `system_files/usr/lib/systemd/user/cosmic-ext-bg-theme.service`
- `system_files/usr/lib/systemd/user/waybar.service`
- `system_files/usr/lib/systemd/user/display-environment.service` (new)
- `system_files/usr/lib/systemd/user-preset/01-cosmoneer.preset`