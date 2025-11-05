# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build /build
COPY custom /custom

# Copy applet artifacts if available (handle missing directory gracefully)
ARG APPLET_ARTIFACTS_DIR=/dev/null
COPY ${APPLET_ARTIFACTS_DIR} /applets-artifacts 2>/dev/null || true

###############################################################################
# PROJECT NAME CONFIGURATION
###############################################################################
# Name: cosmoneer
###############################################################################

# Base Image
FROM ghcr.io/ublue-os/bluefin:stable

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
    /ctx/build/10-build.sh && \
    /ctx/build/30-cosmic-desktop.sh && \
    /ctx/build/35-cosmic-niri-ext.sh && \
    /ctx/build/36-cosmic-applets.sh && \
    /ctx/build/50-extras.sh && \
    echo "Build scripts completed successfully"
    
### LINTING
## Verify final image and contents are correct.
RUN echo "Running container lint..." && \
    bootc container lint && \
    echo "Container lint passed successfully"
