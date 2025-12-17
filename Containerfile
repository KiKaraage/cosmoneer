FROM scratch AS ctx
COPY build /build
COPY custom /custom
COPY system_files /system_files

ARG APPLET_ARTIFACTS_DIR=./applets-artifacts
COPY ${APPLET_ARTIFACTS_DIR} /applets-artifacts

FROM ghcr.io/ublue-os/base-main:43

# Build args: image tag (YYMMDD or YYMMDD.x format) and
# full version string for image (YYMMDD or YYMMDD.x or PR.YYMMDD)
ARG BUILD_IMAGE_TAG=daily
ARG BUILD_VERSION=daily
LABEL org.opencontainers.image.description="A scroller desktop image with COSMIC, Niri and Bluefin goodies together"

### MODIFICATIONS - the following RUN directive does all the things required to run scripts as recommended.

RUN rm /opt && mkdir /opt
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    set -euo pipefail && \

    # Aggressive cleanup before build to maximize space
    dnf5 clean all && \
    rm -rf /var/cache/dnf/* /var/log/* /tmp/* && \

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

    # Base image with identification
    /ctx/build/0-base.sh && \
     BUILD_VERSION="${BUILD_VERSION}" UBLUE_IMAGE_TAG="${BUILD_IMAGE_TAG}" /ctx/build/1-image-id.sh && \
    dnf5 clean all && rm -rf /var/cache/dnf/* && \

    # Hardware & packages
    /ctx/build/2-kernel-hardware.sh && \
    /ctx/build/3-packages.sh && \
    dnf5 clean all && rm -rf /var/cache/dnf/* && \

    # Desktops, applets & system configs
    /ctx/build/4-desktop.sh && \
    /ctx/build/5-applets.sh && \
    /ctx/build/6-systemconf.sh && \

    # Final aggressive cleanup to reduce image size
    dnf5 clean all && \
    rm -rf /var/tmp/* /tmp/* /var/log/* /var/cache/dnf/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    echo "Build scripts completed successfully" && \

### LINTING - Verify final image and contents are correct.

RUN echo "Running container lint..." && \
    bootc container lint && \
    echo "Container lint passed successfully"
