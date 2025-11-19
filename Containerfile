# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build /build
COPY custom /custom
COPY system_files /system_files

# Copy applet artifacts if available (handle missing directory gracefully)
ARG APPLET_ARTIFACTS_DIR=./applets-artifacts
COPY ${APPLET_ARTIFACTS_DIR} /applets-artifacts

# Build image tag (YYMMDD or YYMMDD.x format)
ARG BUILD_IMAGE_TAG=daily

# Full version string for image (YYMMDD or YYMMDD.x or PR.YYMMDD)
ARG BUILD_VERSION=daily

###############################################################################
# PROJECT NAME CONFIGURATION
###############################################################################
# Name: cosmoneer
###############################################################################

# Base Image
FROM ghcr.io/ublue-os/base-main:43

# Image metadata to override base image description
LABEL org.opencontainers.image.description="A scroller desktop image with COSMIC, Niri and Bluefin goodies together"

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build scripts
## the following RUN directive does all the things required to run scripts as recommended.
## Scripts are run in numerical order (10-build.sh, 20-example.sh, etc.)

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    set -e && \
    # Disk space reporting function \
    report_disk_space() { \
        echo "=== DISK SPACE REPORT: $1 ===" && \
        echo "Root filesystem usage:" && \
        df -h / && \
        echo "Largest directories in /:" && \
        du -sh /* 2>/dev/null | sort -hr | head -10 && \
        echo "Package cache size:" && \
        du -sh /var/cache/dnf 2>/dev/null || echo "No dnf cache found" && \
        echo "================================="; \
    } && \
    # Aggressive cleanup before build to maximize space \
    dnf5 clean all && \
    rm -rf /var/cache/dnf/* /var/log/* /tmp/* || true && \
    report_disk_space "Initial state" && \
    echo "Setting up applets directory..." && \
    mkdir -p /applets && \
    if [ -d "/ctx/applets-artifacts" ] && [ "$(ls -A /ctx/applets-artifacts 2>/dev/null)" ]; then \
        echo "Found applet artifacts, copying to /applets..." && \
        cp -r /ctx/applets-artifacts/* /applets/ && \
        echo "Applet artifacts copied successfully:" && \
        ls -la /applets/ || true; \
    else \
        echo "No applet artifacts found, /applets will be empty"; \
    fi && \
    echo "Running build scripts..." && \
    echo "BUILD_IMAGE_TAG=${BUILD_IMAGE_TAG}" && \
    echo "BUILD_VERSION=${BUILD_VERSION}" && \
    # Run build scripts with cleanup and disk space reporting \
    /ctx/build/00-base.sh && report_disk_space "After 00-base.sh" && \
    UBLUE_IMAGE_TAG="${BUILD_IMAGE_TAG}" VERSION="${BUILD_VERSION}" /ctx/build/01-image-id.sh && report_disk_space "After 01-image-id.sh" && \
    dnf5 clean all && rm -rf /var/cache/dnf/* || true && report_disk_space "After cleanup (base scripts)" && \
    /ctx/build/10-kernel-hardware.sh && report_disk_space "After 10-kernel-hardware.sh" && \
    /ctx/build/11-packages.sh && report_disk_space "After 11-packages.sh" && \
    dnf5 clean all && rm -rf /var/cache/dnf/* || true && report_disk_space "After cleanup (package scripts)" && \
    /ctx/build/20-desktop.sh && report_disk_space "After 20-desktop.sh" && \
    /ctx/build/21-desktop-config.sh && report_disk_space "After 21-desktop-config.sh" && \
    /ctx/build/22-desktop-applets.sh && report_disk_space "After 22-desktop-applets.sh" && \
    /ctx/build/23-system-files.sh && report_disk_space "After 23-system-files.sh" && \
    /ctx/build/30-extras.sh && report_disk_space "After 30-extras.sh" && \
    /ctx/build/99-cleanup.sh && report_disk_space "After 99-cleanup.sh" && \
    echo "Build scripts completed successfully" && \
    # Final aggressive cleanup to reduce image size \
    dnf5 clean all && \
    rm -rf /var/tmp/* /tmp/* /var/log/* /var/cache/dnf/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* || true && \
    report_disk_space "Final state after all cleanup"
    
### LINTING
## Verify final image and contents are correct.
RUN echo "Running container lint..." && \
    bootc container lint && \
    echo "Container lint passed successfully"
