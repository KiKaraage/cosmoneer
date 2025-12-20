FROM scratch AS ctx

ARG APPLET_ARTIFACTS_DIR=./applets-artifacts
COPY ${APPLET_ARTIFACTS_DIR} /applets-artifacts

COPY build /build
COPY custom /custom
COPY system_files /system_files
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /files

FROM ghcr.io/ublue-os/base-main:43

ARG BUILD_IMAGE_TAG=daily
ARG BUILD_VERSION=daily
LABEL org.opencontainers.image.description="A scroller desktop image with COSMIC, Niri and Bluefin goodies together"

### MODIFICATIONS - the following RUN directive does all the things required to run scripts as recommended.

### STAGE 0: Setup
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="setup" \
    set -euo pipefail && \
    rm /opt && mkdir /opt && \
    dnf5 clean all && rm -rf /var/cache/dnf/* /var/log/* /tmp/* && \
    mkdir -p /applets && \
    if [ -d "/ctx/applets-artifacts" ] && [ "$(ls -A /ctx/applets-artifacts 2>/dev/null)" ]; then \
        cp -r /ctx/applets-artifacts/* /applets/ && \
        echo "✅ Applet artifacts copied successfully" && \
        ls -la /applets/ || true; \
    else \
        echo "ℹ️ No applet artifacts found"; \
    fi && \
    echo "✅ Context setup completed"

### STAGE 1: Base Identity
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="base-identity" \
    /ctx/build/0-base.sh && \
    BUILD_VERSION="${BUILD_VERSION}" UBLUE_IMAGE_TAG="${BUILD_IMAGE_TAG}" /ctx/build/1-id.sh && \
    echo "✅ Base identity completed"

### STAGE 2: System Packages
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/rpm \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="packages" \
    /ctx/build/2-dnf.sh && \
    dnf5 clean all && rm -rf /var/cache/dnf/* && \
    echo "✅ System packages completed"

### STAGE 3: UBlue Integration
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="ublue" \
    /ctx/build/3-ublue.sh && \
    echo "✅ UBlue integration completed"

### STAGE 4: Niri Desktop
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache/dnf \
    --label build.stage="niri" \
    /ctx/build/4-niri.sh && \
    echo "✅ Niri desktop completed"

### STAGE 5: COSMIC Desktop
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="cosmic" \
    /ctx/build/5-cosmic.sh && \
    echo "✅ COSMIC desktop completed"

### STAGE 6: COSMIC Applets & Binaries
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="applets" \
    /ctx/build/6-applets.sh && \
    echo "✅ Applets completed"

### STAGE 7: System Configuration & Cleanup
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=tmpfs,dst=/tmp \
    --label build.stage="system-config" \
    /ctx/build/7-systemconf.sh && \
    dnf5 clean all && \
    rm -rf /var/tmp/* /tmp/* /var/log/* /var/cache/dnf/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    echo "✅ Build completed successfully"

### STAGE 8: Validation
RUN --label build.stage="validation" \
    bootc container lint && \
    echo "✅ Container validation passed"
