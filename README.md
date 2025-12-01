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
- Reboot and you;ll meet COSMIC's greeter! Chose Niri for the scroller experience, or COSMIC if you want the regular version of the DE

## About This Image

| Aspects | Choices | Sources |
|---------|-------- | ------- |
| Base OS | Fedora 43 | `ghcr.io/ublue-os/base-main:43` | 
| DE & WM | Nightly `cosmic-desktop` + Nightly `niri-git` | [ryanabx/cosmic-epoch](https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/), [yalter/niri-git](https://copr.fedorainfracloud.org/coprs/yalter/niri-git/) |
| Kernel  | Gated, similar to Bluefin/Aurora stable | [ublue-os/packages](https://copr.fedorainfracloud.org/coprs/ublue-os/packages/) |
| Others  | `ublue-brew`, `uupd`, `ublue-bling` enabled | [ublue-os/packages](https://copr.fedorainfracloud.org/coprs/ublue-os/packages/) |

### Benefits and Compromises

- Fuzzel is installed if you want faster, more relible launcher
- Alacrittty is installed if you want a faster terminal
- Some non-flatpak applets are installed by default, see below
- Compromises for Niri session:
  - COSMIC's app list (taskbar) doesn't worked at all
    - But Waybar is installed (and preconfigured) to show taskbar of active applications when you hover to bottom center part of your screen!
  - Also the shortcut section on COSMIC Settings app doesn't work on Niri, you have to edit .config/niri/config.kdl and add your own screenshots
    - (I might cook up a preconfigured kdl with middle ground between COSMIC and Niri default keybinds)
  - COSMIC idle stuff doesn't work too
    - But swayidle works! It's set to 10 minutes for auto screen off and 30 minutes for auto suspend
  - and more (to be edited) 

### Applets

| Applet Name | Description | Source | Status | 
| ----------- | ----------- | ------ | ------ |
| cosmic-ext-applet-emoji-selector | Emoji selector | Git | Working (but the emojis rendered blank) | 
| cosmic-ext-applet-vitals | System monitoring | Git | Working |
| cosmic-ext-applet-caffeine | Keep device idle | Git | Working |
| cosmic-ext-applet-clipboard-manager | Clipboard manager | Git | Working with no icon |
| cosmic-ext-applet-privacy-indicator | Indicator for webcam/mic activity | GH Release (RPM) | Working (but not when wf-recorder is active) |
| cosmic-ext-applet-ollama | Chat with local LLM via Ollama | Git | Working (but my system is too weak for it anyway) |

### Tools

| Tool Name | Description | Source | Status |
| --------- | ----------- | ------ | ------ |
| cosmic-ext-alternative-startup | Making Niri session work on COSMIC | Git | Works |
| cosmic-ext-bg-theme | Dynamic theming based on wallpaper | Git | Working |
| wf-recorder-gui | Screenrecording app using wf-recorder | Git | Working only on Niri session |

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
- `ujust show-niri-config` - Display current Niri configuration
- `ujust reset-niri-config` - Reset Niri to defaults
- `ujust configure-dev-groups` - Add user to docker and libvirt groups

*Last updated: 2025-12-02*

## Communities

- [bootc Discussion](https://github.com/bootc-dev/bootc/discussions)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [Zirconium](https://github.com/zirconium-dev/zirconium/) Discord for Niri talks
- [Niri](https://github.com/YaLTeR/niri) Discord for actual Niri talks
- [Pop!_OS ~~Slack~~ Mattermost](https://chat.pop-os.org/) for COSMIC talks, updates, complaints with System76 folks
- [Fedora COSMIC Matrix](https://matrix.to/#/#cosmic:fedoraproject.org) for COSMIC talks with Ryanabx, the Fedora maintainer

## Learn More

- [Universal Blue Documentation](https://universal-blue.org/)
- [bootc Documentation](https://containers.github.io/bootc/)
- [Video Tutorial by TesterTech](https://www.youtube.com/watch?v=IxBl11Zmq5wE)
