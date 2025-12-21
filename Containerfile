FROM scratch AS ctx
COPY build /build
COPY custom /custom
COPY system_files /system_files

ARG APPLET_ARTIFACTS_DIR=./applets-artifacts
COPY ${APPLET_ARTIFACTS_DIR} /applets-artifacts

FROM ghcr.io/ublue-os/base-main:43

ARG BUILD_IMAGE_TAG=daily
ARG BUILD_VERSION=daily
LABEL org.opencontainers.image.description="A scroller desktop image with COSMIC, Niri and Bluefin goodies together"

### MODIFICATIONS - the following RUN directive does all the things required to run scripts as recommended.

RUN rm /opt && mkdir /opt
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    echo "Setting up applets directory..." && \
    mkdir -p /applets && \
    if [ -d "/ctx/applets-artifacts" ] && [ "$(ls -A /ctx/applets-artifacts 2>/dev/null)" ]; then \
        echo "Found applet artifacts, copying to /applets..." && \
        cp -r /ctx/applets-artifacts/* /applets/ && \
        echo "Applet artifacts copied successfully:" && \
        ls -la /applets/ || true; \
    else \
        echo "No applet artifacts found, /applets will be empty"; \
    fi

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    set -euo pipefail && \
    dnf5 clean all && \
    rm -rf /var/cache/dnf/* /var/log/* /tmp/* && \

    echo "Running build scripts..." && \
    echo "BUILD_IMAGE_TAG=${BUILD_IMAGE_TAG}" && \
    echo "BUILD_VERSION=${BUILD_VERSION}" && \
    /ctx/build/0-base.sh && \
    BUILD_VERSION="${BUILD_VERSION}" UBLUE_IMAGE_TAG="${BUILD_IMAGE_TAG}" /ctx/build/1-id.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/2-fedora.sh && \
    /ctx/build/3-ublue.sh && \
    dnf5 clean all

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/4-niri.sh && \
    /ctx/build/5-cosmic.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/6-extras.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/7-systemconf.sh && \
    dnf5 clean all && \
    rm -rf /var/tmp/* /tmp/* /var/log/* /var/cache/dnf/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    echo "Build scripts completed successfully"

### LINTING - Verify final image and contents are correct.

RUN bootc container lint && \
    echo "Container lint passed successfully"
