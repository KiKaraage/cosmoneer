# cosmoneer

A proof-of-concept to bring COSMIC + Niri + Bluefin goodies together into a scroller desktop OS. Sane defaults from Universal Blue with System76's COSMIC desktop environment, the Niri scrollable tiling compositor, and Docker group access.

Try it:
- Install a Fedora Atomic variant, like [Bluefin](https://projectbluefin.io)
- Run `sudo bootc switch ghcr.io/kikaraage/cosmoneer`
- **COSMIC + Niri Integration:** After your first login, run `ujust configure-niri-cosmic` to configure COSMIC apps and keybindings inside Niri. Use `ujust show-niri-config` to review the configuration or `ujust reset-niri-config` to roll back to defaults.

## About This Image

This image is based on **Bluefin stable** and includes these customizations:

### Desktop Environment
- **COSMIC Desktop** - System76's next-generation desktop environment built in Rust ([ryanabx/cosmic-epoch](https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/))
- **Niri Window Manager** - Scrollable-tiling Wayland compositor ([yalter/niri-git](https://copr.fedorainfracloud.org/coprs/yalter/niri-git/))
- **COSMIC-Niri Integration** - Run COSMIC apps in Niri via cosmic-ext-alternative-startup
- GNOME has been removed to reduce image size

### Multimedia Support
- FFmpeg with full codec support
- GStreamer plugins (good, base, bad-free)
- Video thumbnail support for file managers
- LAME audio codecs
- Modern image format support (libjxl)

### Developer Tools
- **Docker CE** - Latest Docker Engine with docker-compose plugin
- **Additional Fonts** - JetBrains Mono, Fira Code and more
- SSH agent enabled globally
- Docker group pre-configured

### Added Applications
- **GPU Screen Recorder** - Efficient screen recording with hardware acceleration
- COSMIC Terminal (cosmic-term) included with COSMIC desktop

### ujust Commands
- `ujust configure-niri-cosmic` - Configure Niri for COSMIC integration
- `ujust show-niri-config` - Display current Niri configuration
- `ujust reset-niri-config` - Reset Niri to defaults
- `ujust configure-dev-groups` - Add user to docker and libvirt groups

*Last updated: 2024-11-03*

## For admin: What's Included

### Build System
- Automated builds via GitHub Actions on every commit
- Awesome self hosted Renovate setup that keeps all your images and actions up to date.
- Automatic cleanup of old images (90+ days) to keep it tidy
- Pull request workflow - test changes before merging to main
  - PRs build and validate before merge
  - `main` branch builds `:stable` images
- Validates your files on pull requests so you never break a build:
  - Brewfile, Justfile, ShellCheck, Renovate config, and it'll even check to make sure the flatpak you add exists on FlatHub
- Production Grade Features
  - Container signing, SBOM Generation, and layer rechunking.
  - See checklist below to enable these as they take some manual configuration

### Homebrew Integration
- Pre-configured Brewfiles for easy package installation and customization
- Includes curated collections: development tools, fonts, CLI utilities. Go nuts.
- Users install packages at runtime with `brew bundle`, aliased to premade `ujust commands`
- See [custom/brew/README.md](custom/brew/README.md) for details

### Flatpak Support
- Ship your favorite flatpaks
- Automatically installed on first boot after user setup
- See [custom/flatpaks/README.md](custom/flatpaks/README.md) for details

### Rechunker
- Optimizes container image layer distribution for better download resumability
- Based on [hhd-dev/rechunk](https://github.com/hhd-dev/rechunk) v1.2.4
- Disabled by default for faster initial builds
- Enable in `.github/workflows/build.yml` by uncommenting the rechunker steps (see comments in file)
- Recommended for production deployments after initial testing

### ujust Commands
- User-friendly command shortcuts via `ujust`
- Pre-configured examples for app installation and system maintenance for you to customize
- See [custom/ujust/README.md](custom/ujust/README.md) for details

### Build Scripts
- Modular numbered scripts (10-, 20-, 30-) run in order
- Example scripts included for third-party repositories and desktop replacement
- Helper functions for safe COPR usage
- See [build/README.md](build/README.md) for details

## For Admin: Quick Start

### 1. Create Your Repository

Click "Use this template" to create a new repository from this template.

### 2. Rename the Project

Important: Change `cosmoneer` to your repository name in these 5 files:

1. `Containerfile` (line 9): `# Name: your-repo-name`
2. `Justfile` (line 1): `export image_name := "your-repo-name"`
3. `README.md` (line 1): `# your-repo-name`
4. `artifacthub-repo.yml` (line 5): `repositoryID: your-repo-name`
5. `custom/ujust/README.md` (~line 175): `localhost/your-repo-name:stable`

### 3. Enable GitHub Actions

- Go to the "Actions" tab in your repository
- Click "I understand my workflows, go ahead and enable them"

Your first build will start automatically! 

Note: Image signing is disabled by default. Your images will build successfully without any signing keys. Once you're ready for production, see "Optional: Enable Image Signing" below.

### 4. Customize Your Image

Choose your base image in `Containerfile` (line 23):
```dockerfile
FROM ghcr.io/ublue-os/bluefin:stable
```

Add your packages in `build/10-build.sh`:
```bash
dnf5 install -y package-name
```

Customize your apps:
- Add Brewfiles in `custom/brew/` ([guide](custom/brew/README.md))
- Add Flatpaks in `custom/flatpaks/` ([guide](custom/flatpaks/README.md))
- Add ujust commands in `custom/ujust/` ([guide](custom/ujust/README.md))

### 5. Development Workflow

All changes should be made via pull requests:

1. Open a pull request on GitHub with the change you want.
3. The PR will automatically trigger:
   - Build validation
   - Brewfile, Flatpak, Justfile, and shellcheck validation
   - Test image build
4. Once checks pass, merge the PR
5. Merging triggers publishes a `:stable` image

### 6. Deploy Your Image

Switch to your image:
```bash
sudo bootc switch ghcr.io/your-username/your-repo-name:stable
sudo systemctl reboot
```

## For Admin: Enable Image Signing

Image signing is disabled by default to let you start building immediately. However, signing is strongly recommended for production use.

### Why Sign Images?

- Verify image authenticity and integrity
- Prevent tampering and supply chain attacks
- Required for some enterprise/security-focused deployments
- Industry best practice for production images

### Setup Instructions

1. Generate signing keys:
```bash
cosign generate-key-pair
```

This creates two files:
- `cosign.key` (private key) - Keep this secret
- `cosign.pub` (public key) - Commit this to your repository

2. Add the private key to GitHub Secrets:
   - Copy the entire contents of `cosign.key`
   - Go to your repository on GitHub
   - Navigate to Settings → Secrets and variables → Actions ([GitHub docs](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository))
   - Click "New repository secret"
   - Name: `SIGNING_SECRET`
   - Value: Paste the entire contents of `cosign.key`
   - Click "Add secret"

3. Replace the contents of `cosign.pub` with your public key:
   - Open `cosign.pub` in your repository
   - Replace the placeholder with your actual public key
   - Commit and push the change

4. Enable signing in the workflow:
   - Edit `.github/workflows/build.yml`
   - Find the "OPTIONAL: Image Signing with Cosign" section.
   - Uncomment the steps to install Cosign and sign the image (remove the `#` from the beginning of each line in that section).
   - Commit and push the change

5. Your next build will produce signed images!

Important: Never commit `cosign.key` to the repository. It's already in `.gitignore`.

## For Admin: Love It? Let's Go to Production

Ready to take your custom OS to production? Enable these features for enhanced security, reliability, and performance:

### Production Checklist

- [ ] **Enable Image Signing** (Recommended)
  - Provides cryptographic verification of your images
  - Prevents tampering and ensures authenticity
  - See "Optional: Enable Image Signing" section above for setup instructions
  - Status: **Disabled by default** to allow immediate testing

- [ ] **Enable Rechunker** (Recommended)
  - Optimizes image layer distribution for better download resumability
  - Improves reliability for users with unstable connections
  - To enable:
    1. Edit `.github/workflows/build.yml`
    2. Find the "Rechunk (OPTIONAL)" section around line 121
    3. Uncomment the "Run Rechunker" step
    4. Uncomment the "Load in podman and tag" step
    5. Comment out the "Tag for registry" step that follows
    6. Commit and push
  - Status: **Disabled by default** for faster initial builds

- [ ] **Enable SBOM Attestation** (Recommended)
  - Generates Software Bill of Materials for supply chain security
  - Provides transparency about what's in your image
  - Requires image signing to be enabled first
  - To enable:
    1. First complete image signing setup above
    2. Edit `.github/workflows/build.yml`
    3. Find the "OPTIONAL: SBOM Attestation" section around line 232
    4. Uncomment the "Add SBOM Attestation" step
    5. Commit and push
  - Status: **Disabled by default** (requires signing first)

### After Enabling Production Features

Your workflow will:
- Sign all images with your key
- Generate and attach SBOMs
- Optimize layers for better distribution
- Provide full supply chain transparency

Users can verify your images with:
```bash
cosign verify --key cosign.pub ghcr.io/your-username/your-repo-name:stable
```

## For contributors: Detailed Guides

- [Homebrew/Brewfiles](custom/brew/README.md) - Runtime package management
- [Flatpak Preinstall](custom/flatpaks/README.md) - GUI application setup
- [ujust Commands](custom/ujust/README.md) - User convenience commands
- [Build Scripts](build/README.md) - Build-time customization

## For contributors: Local Testing

Test your changes before pushing:

```bash
just build              # Build container image
just build-qcow2        # Build VM disk image
just run-vm-qcow2       # Test in browser-based VM
```

## Community

- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc Discussion](https://github.com/bootc-dev/bootc/discussions)
- I personally hang out on [Origami Linux Discord server](https://discord.com/channels/1434166231274885313/1434166233816764529), a fellow COSMIC-based image. [Check Origami Linux repository](https://github.com/john-holt4/Origami-Linux) too!

## Learn More

- [Universal Blue Documentation](https://universal-blue.org/)
- [bootc Documentation](https://containers.github.io/bootc/)
- [Video Tutorial by TesterTech](https://www.youtube.com/watch?v=IxBl11Zmq5wE)

## Security

This template provides security features for production use:
- Optional SBOM generation (Software Bill of Materials) for supply chain transparency
- Optional image signing with cosign for cryptographic verification
- Automated security updates via Renovate
- Build provenance tracking

These security features are disabled by default to allow immediate testing. When you're ready for production, see the "Let's Go to Production" section above to enable them.

---

Template maintained by [Universal Blue Project](https://universal-blue.org/)

