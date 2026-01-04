FROM scratch AS ctx
COPY build /build
COPY custom /custom
COPY system_files /system_files

# Add Brew from OCI containers
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /oci/brew
COPY --from=ghcr.io/projectbluefin/common:latest /system_files/shared /oci/shared

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
    set -euo pipefail && \
    /ctx/build/2-fedora.sh && \
    dnf5 clean all

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    echo "DEBUG: Checking /ctx/oci/ contents:" && \
    ls -la /ctx/oci/ 2>/dev/null || echo "No /ctx/oci/ directory found" && \
    if [ -d "/ctx/oci/brew" ]; then \
        cp -r /ctx/oci/brew/usr/lib/systemd/system/* /usr/lib/systemd/system/ && \
        cp -r /ctx/oci/brew/usr/share/homebrew.tar.zst /usr/share/homebrew.tar.zst; \
    else \
        echo "Brew OCI artifacts not found - skipping brew setup"; \
    fi && \
    echo "DEBUG: Checking /ctx/oci/brew/ contents:" && \
    ls -la /ctx/oci/brew/ 2>/dev/null || echo "No /ctx/oci/brew/ directory" && \
    echo "Installing projectbluefin/common OCI artifacts..." && \
    echo "DEBUG: Checking /ctx/oci/shared/ contents:" && \
    ls -la /ctx/oci/shared/ 2>/dev/null || echo "No /ctx/oci/shared/ directory" && \
    if [ -d "/ctx/oci/shared/usr" ]; then \
        cp -r /ctx/oci/shared/usr/lib/systemd/system/* /usr/lib/systemd/system/ && \
        cp -r /ctx/oci/shared/etc/* /etc/; \
    else \
        echo "projectbluefin/common OCI artifacts not found - skipping"; \
    fi && \
    echo "DEBUG: Checking copied services..." && \
    ls -la /usr/lib/systemd/system/brew* /usr/lib/systemd/system/flatpak-preinstall.service /usr/lib/systemd/system/ublue-system-setup.service 2>/dev/null || echo "Copied services not found" && \
    echo "DEBUG: Presetting services..." && \
    echo "Available services:" && \
    ls /usr/lib/systemd/system/*service /usr/lib/systemd/system/*timer 2>/dev/null | head -20 || true && \
    echo "Presetting brew-setup.service..." && \
    (systemctl preset brew-setup.service && echo "SUCCESS") || (echo "FAILED" && exit 1) && \
    echo "Presetting brew-upgrade.timer..." && \
    (systemctl preset brew-upgrade.timer && echo "SUCCESS") || (echo "FAILED" && exit 1) && \
    echo "Presetting brew-update.timer..." && \
    (systemctl preset brew-update.timer && echo "SUCCESS") || (echo "FAILED" && exit 1) && \
    echo "Presetting flatpak-preinstall.service..." && \
    (systemctl preset flatpak-preinstall.service && echo "SUCCESS") || (echo "FAILED" && exit 1) && \
    echo "Presetting ublue-system-setup.service..." && \
    (systemctl preset ublue-system-setup.service && echo "SUCCESS") || (echo "FAILED" && exit 1)
    
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    set -euo pipefail && \
    /ctx/build/3-ublue.sh && \
    /ctx/build/4-niri.sh && \
    /ctx/build/5-cosmic.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    set -euo pipefail && \
    cp /ctx/build/applets.yml /applets.yml && \
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
