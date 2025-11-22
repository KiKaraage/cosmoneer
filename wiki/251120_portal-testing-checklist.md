# Portal System Testing Checklist - Working Indicators

## Success Criteria for Portal Fixes

### 1. Display Environment Service
**Command**: `systemctl --user status display-environment.service`

**Working Indicator**:
```
● display-environment.service - Import display environment and restart portals
     Loaded: loaded (/usr/lib/systemd/user/display-environment.service; enabled; preset: disabled)
     Active: active (exited) since [timestamp]; [duration] ago
   Main PID: [PID] (code=exited, status=0/SUCCESS)
```

**Failure Indicators**:
- `bad-setting` or `failed` status
- `Unit display-environment.service has a bad unit file setting`
- `Active: inactive (dead)`

### 2. Environment Variables Imported
**Command**: `systemctl --user show-environment | grep -E "(WAYLAND|DISPLAY|XDG)" | sort`

**Working Indicator**:
```
DISPLAY=:1
WAYLAND_DISPLAY=wayland-1
XDG_CURRENT_DESKTOP=niri
XDG_SESSION_TYPE=wayland
```

**Failure Indicators**:
- Missing `WAYLAND_DISPLAY` or `DISPLAY` variables
- Only `XDG_SESSION_TYPE=wayland` present (missing display variables)

### 3. Portal Services Status
**Command**: `systemctl --user status xdg-desktop-portal*`

**Working Indicator**:
```
● xdg-desktop-portal.service - Portal service
     Active: active (running)

● xdg-desktop-portal-gnome.service - Portal service (GNOME implementation)
     Active: active (running)

○ xdg-desktop-portal-cosmic.service - Portal service (COSMIC implementation)
     Active: inactive (dead)  # Expected in hybrid environment
```

**Failure Indicators**:
- `xdg-desktop-portal-gtk.service` showing `cannot open display` errors
- `xdg-desktop-portal-gnome.service` showing `Non-compatible display server`
- Multiple portal services in `failed` state

### 4. Portal Service Logs
**Command**: `journalctl --user -u xdg-desktop-portal -n 20 --no-pager`

**Working Indicator**:
```
Nov 20 16:25:31 X230 /usr/libexec/xdg-desktop-portal[2136]: Choosing gnome.portal for org.freedesktop.impl.portal.FileChooser
Nov 20 16:25:31 X230 /usr/libexec/xdg-desktop-portal[2136]: Choosing cosmic.portal for org.freedesktop.impl.portal.Screenshot
Nov 20 16:25:31 X230 systemd[1736]: Started xdg-desktop-portal.service - Portal service.
```

**Failure Indicators**:
- `Could not activate remote peer 'org.freedesktop.impl.portal.desktop.gtk': startup job failed`
- `Choosing gtk.portal for org.freedesktop.impl.portal.FileChooser as a last-resort fallback`
- `Failed to ReadAll() from Settings implementation`

### 5. GNOME Portal Logs
**Command**: `journalctl --user -u xdg-desktop-portal-gnome -n 10 --no-pager`

**Working Indicator**:
```
Nov 20 16:25:31 X230 systemd[1736]: Started xdg-desktop-portal-gnome.service - Portal service.
Nov 20 16:25:31 X230 xdg-desktop-portal-gnome[PID]: Successfully initialized
```

**Failure Indicators**:
- `Non-compatible display server, exposing settings only.`
- `Failed to open service channel Wayland connection`
- `cannot open display:`

### 6. File Picker Testing
**Test**: Open file dialog in native GTK app (gedit, nautilus, etc.)

**Working Indicator**:
- GNOME/Nautilus file picker dialog appears
- No error messages in terminal
- File selection works properly

**Failure Indicators**:
- Basic GTK file dialog (limited functionality)
- Error messages about portal failures
- Application crashes or hangs

## Complete Success Scenario

### All Services Running Correctly:
```bash
# Environment service working
systemctl --user status display-environment.service
# → Active: active (exited)

# Environment variables imported
systemctl --user show-environment | grep WAYLAND
# → WAYLAND_DISPLAY=wayland-1

# Portal services working
systemctl --user status xdg-desktop-portal*
# → xdg-desktop-portal: active (running)
# → xdg-desktop-portal-gnome: active (running)

# Portal logs show proper backend selection
journalctl --user -u xdg-desktop-portal
# → Choosing gnome.portal for org.freedesktop.impl.portal.FileChooser

# File picker works in GTK apps
# → Nautilus file dialog appears
```

## Troubleshooting Commands

### Quick Status Check:
```bash
systemctl --user status display-environment.service xdg-desktop-portal xdg-desktop-portal-gnome
systemctl --user show-environment | grep -E "(WAYLAND|DISPLAY)"
```

### Detailed Log Analysis:
```bash
journalctl --user -u xdg-desktop-portal -f
journalctl --user -u xdg-desktop-portal-gnome -n 20
journalctl --user -u display-environment.service -n 10
```

### Manual Testing:
```bash
# Test environment import
systemctl --user import-environment WAYLAND_DISPLAY DISPLAY

# Test portal restart
systemctl --user restart xdg-desktop-portal-gnome.service

# Test file picker
echo "test" | gedit
```

## Expected Final State

After successful deployment:
1. **display-environment.service**: Runs once, imports environment, exits successfully
2. **Portal services**: Start with proper display environment
3. **File picker**: Uses GNOME/Nautilus implementation for consistency
4. **No more**: "cannot open display" or "startup job failed" errors