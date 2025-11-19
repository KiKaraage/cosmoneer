# Niri & COSMIC Portal Configuration

## Overview
This document details the configuration strategy for integrating `xdg-desktop-portal-cosmic` with the Niri window manager in the Cosmoneer project. The goal is to ensure reliable portal functionality (file chooser, etc.) without relying on brittle hacks or hardcoded service files.

## The Problem
Initial attempts to run the COSMIC portal failed with "cannot open display" errors. The root causes were:
1.  **Hardcoded Environment Variables**: Service files hardcoded `WAYLAND_DISPLAY=wayland-1`. While Niri might default to this, hardcoding it in the unit file is inflexible and fails if the socket name changes.
2.  **Missing Environment in Systemd**: The systemd user session (which spawns the portal service) did not have access to the `WAYLAND_DISPLAY` or `DISPLAY` variables, meaning it couldn't connect to the compositor even if the socket was correct.
3.  **Redundant Wrappers**: The build process created wrapper scripts (`xdg-desktop-portal-cosmic-wrapper`) that were then bypassed or conflicted with the service file definitions.

## The Solution

### 1. Clean Service Definition
We cleaned up `/usr/lib/systemd/user/xdg-desktop-portal-cosmic.service` to be a standard, D-Bus activatable service.
-   **Removed**: Hardcoded `WAYLAND_DISPLAY` and `DISPLAY` variables.
-   **Removed**: Wrapper script usage in `ExecStart`.
-   **Added**: `Type=dbus` and `BusName` to ensure proper D-Bus activation lifecycle management.
-   **Added**: `Alias` to allow activation via the standard portal interface name.

**Resulting Service File:**
```ini
[Unit]
Description=Portal service (COSMIC implementation)
PartOf=graphical-session.target
After=graphical-session.target
Requisite=graphical-session.target

[Service]
Type=dbus
BusName=org.freedesktop.impl.portal.desktop.cosmic
Environment=GDK_BACKEND=wayland
ExecStart=/usr/libexec/xdg-desktop-portal-cosmic
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
Alias=org.freedesktop.impl.portal.desktop.cosmic.service
```

### 2. Session Startup Script
We updated the session startup script (`/usr/bin/start-cosmic-ext-niri`) to handle environment setup **before** the session starts.
-   **Explicit Export**: We explicitly export `WAYLAND_DISPLAY=wayland-1` to ensure consistency between what Niri uses and what we tell systemd.
-   **Systemd Import**: Crucially, we run `systemctl --user import-environment` immediately. This ensures that *any* service started by systemd (including our portal) sees the correct display variables.

**Key snippet from `start-cosmic-ext-niri`:**
```bash
# Set explicit Wayland display
export WAYLAND_DISPLAY=wayland-1
export DISPLAY=:1

# ...

if command -v systemctl >/dev/null; then
    # Import specific variables so portal services can find the socket
    systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP WAYLAND_DISPLAY DISPLAY
fi
```

### 3. Build Cleanup
We updated `build/23-system-files.sh` to stop generating the redundant `xdg-desktop-portal-cosmic-wrapper`. The service now calls the binary directly, which is cleaner and less error-prone.

## Verification
With these changes:
1.  **Activation**: When an app requests a file picker, D-Bus activates `xdg-desktop-portal-cosmic.service`.
2.  **Environment**: The service inherits `WAYLAND_DISPLAY` from the systemd user environment (populated by our startup script).
3.  **Connection**: The portal successfully connects to the Niri socket and renders the file picker using `cosmic-files`.
