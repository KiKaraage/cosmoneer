# cosmoneer

A proof-of-concept to bring COSMIC + Niri + Bluefin goodies together into a scroller desktop OS.

- Stable Fedora 43. Gated Linux kernels. Ease of tool access with Brew. Docker CE group access configured. 
- With Nightly COSMIC **and** Nightly Niri as scrollable tiling compositor. Applets and utilities ready.
- Updated every Monday, Wednesday, Friday midnight UTC!



<img alt="Cosmoneer desktop with Bluefin's Collapse wallpaper" src=".github/assets/01-wallpaper.png" />

<img alt="Cosmoneer desktop with Niri compositor, handling multiple windows horizontally in its scrolling nature" src=".github/assets/02-multitasking.jpg" />

Try it:
- Install a Fedora Atomic variant, like [Bluefin](https://projectbluefin.io)
- Run `sudo bootc switch ghcr.io/kikaraage/cosmoneer`
- COSMIC + Niri Integration: After your first login, run `ujust configure-niri-cosmic` to configure COSMIC apps and keybindings inside Niri. Use `ujust show-niri-config` to review the configuration or `ujust reset-niri-config` to roll back to defaults.

## About This Image



| Aspects | Choices | Sources |
|---------|-------- | ------- |
| Base OS | Fedora 43 | `ghcr.io/ublue-os/base-main:43` | 
| DE & WM | Nightly `cosmic-desktop` + Nightly `niri-git` | [ryanabx/cosmic-epoch](https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/), [yalter/niri-git](https://copr.fedorainfracloud.org/coprs/yalter/niri-git/) |
| Kernel  | Gated, similar to Bluefin/Aurora stable | [ublue-os/packages](https://copr.fedorainfracloud.org/coprs/ublue-os/packages/) |
| Others  | `ublue-brew`, `uupd`, `ublue-bling` enabled | [ublue-os/packages](https://copr.fedorainfracloud.org/coprs/ublue-os/packages/) |

### Benefits and Compromises

Coming soon, check /issues for now. Lots of tradeoffs between cosmic-comp and niri sessions for sure, but it's worth it for me!

### Applets

| Applet Name | Description | Source | Status | 
| ----------- | ----------- | ------ | ------ |
| cosmic-ext-applet-emoji-selector | Emoji selector | Git | Working (but the emojis rendered blank) | 
| cosmic-ext-applet-vitals | System monitoring | Git | Working |
| cosmic-ext-applet-caffeine | Keep device idle | Git | Working (kinda, though the Niri session itself is caffeinated) |
| cosmic-connect-applet | (Supposedly) bridging KDE Connect | Git | Not working, still template-y |
| cosmic-ext-applet-clipboard-manager | Clipboard manager | Git | Working with no icon |
| cosmic-ext-applet-privacy-indicator | Indicator for webcam/mic activity | GH Release (RPM) | Working (but not when wf-recorder is active) |
| cosmic-ext-applet-ollama | Chat with local LLM via Ollama | Git | Working (but my system is too weak for it anyway) |

### Tools

| Tool Name | Description | Source | Status |
| --------- | ----------- | ------ | ------ |
| cosmic-ext-alternative-startup | Making Niri session work on COSMIC | Git | Half-working (filechooser & app list/taskbar fails) |
| cosmic-ext-bg-theme | Dynamic theming based on wallpaper | Git | Working |
| wf-recorder-gui | Screenrecording app using wf-recorder | Git | Working only on Niri session |
| prtsc-wayland | Faster screencapture utility for cosmic-comp | Git | Working (partial SS doesn't work yet) |

### Other Apps & Multimedia Support
- **Docker CE** - Latest Docker Engine with docker-compose plugin
- SSH agent enabled globally
- Docker group pre-configured
- **Fonts preinstalled via Brew** - Recommended Cosmic UI font: Work Sans, Bricolage Grotesque, Aptos
- FFmpeg with full codec support
- GStreamer plugins (good, base, bad-free)
- Video thumbnail support for file managers
- LAME audio codecs
- Modern image format support (libjxl)

### ujust Commands (WIP)
- `ujust configure-niri-cosmic` - Configure Niri for COSMIC integration
- `ujust show-niri-config` - Display current Niri configuration
- `ujust reset-niri-config` - Reset Niri to defaults
- `ujust configure-dev-groups` - Add user to docker and libvirt groups

*Last updated: 2025-11-17*

## Communities

- [bootc Discussion](https://github.com/bootc-dev/bootc/discussions)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [Zirconium](https://github.com/zirconium-dev/zirconium/) Discord for Niri talks
- [Niri](https://github.com/YaLTeR/niri) Discord for actual Niri talks
- [Origami Linux](https://github.com/john-holt4/Origami-Linux) Discord for COSMIC talks
- [Pop!_OS ~~Slack~~ Mattermost](https://chat.pop-os.org/) for actual COSMIC talks, updates, complaints
- [Fedora COSMIC Matrix](https://matrix.to/#/#cosmic:fedoraproject.org) for COSMIC talks with Ryanabx, the Fedora maintainer

## Learn More

- [Universal Blue Documentation](https://universal-blue.org/)
- [bootc Documentation](https://containers.github.io/bootc/)
- [Video Tutorial by TesterTech](https://www.youtube.com/watch?v=IxBl11Zmq5wE)
