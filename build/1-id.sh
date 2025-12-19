#!/usr/bin/env bash
set -xeuo pipefail

# Cosmoneer Image Identity

echo "===$(basename "$0")==="

echo "::group:: Add Image Identity"


IMAGE_PRETTY_NAME="Cosmoneer"
IMAGE_NAME="cosmoneer"
IMAGE_VENDOR="KiKaraage"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/KiKaraage/Cosmoneer"
DOCUMENTATION_URL="https://github.com/KiKaraage/Cosmoneer"
SUPPORT_URL="https://github.com/KiKaraage/Cosmoneer/issues"
BUG_SUPPORT_URL="https://github.com/KiKaraage/Cosmoneer/issues"
CODE_NAME="Alpha"
# BUILD_VERSION should always be passed as build arg from Containerfile
# If not set, use current date as fallback (should not happen in CI)
if [[ -z "${BUILD_VERSION:-}" ]]; then
  BUILD_VERSION="$(date +%y%m%d)"
  echo "WARNING: BUILD_VERSION not set, using current date: $BUILD_VERSION" >&2
fi
VERSION="${BUILD_VERSION}"
# UBLUE_IMAGE_TAG should always be passed as build arg from Containerfile
# If not set, use current date as fallback (should not happen in CI)
if [[ -z "${UBLUE_IMAGE_TAG:-}" ]]; then
  UBLUE_IMAGE_TAG="$(date +%y%m%d)"
  echo "WARNING: UBLUE_IMAGE_TAG not set, using current date: $UBLUE_IMAGE_TAG" >&2
fi

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

# Base image information
BASE_IMAGE_NAME="base-main"
FEDORA_MAJOR_VERSION="43"

# Image Flavor
image_flavor="cosmic"
if [[ "${IMAGE_NAME}" =~ nvidia-open ]]; then
  image_flavor="cosmic-nvidia-open"
fi

cat >$IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$image_flavor",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag":"$UBLUE_IMAGE_TAG",
  "base-image-name": "$BASE_IMAGE_NAME",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF

# OS Release File
sed -i "s|^VARIANT_ID=.*|VARIANT_ID=$IMAGE_NAME|" /usr/lib/os-release
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} (${VERSION})\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"$IMAGE_PRETTY_NAME\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora:.*\"|CPE_NAME=\"cpe:/o:universal-blue:${IMAGE_PRETTY_NAME,}:${VERSION}\"|" /usr/lib/os-release
sed -i "s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,}\"|" /usr/lib/os-release
sed -i "s|^ID=fedora|ID=${IMAGE_PRETTY_NAME,}\nID_LIKE=\"${IMAGE_LIKE}\"|" /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (${BASE_IMAGE_NAME^})\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release

if [[ -n "${SHA_HEAD_SHORT:-}" ]]; then
  echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >>/usr/lib/os-release
fi

# Added in systemd 249.
# https://www.freedesktop.org/software/systemd/man/latest/os-release.html#IMAGE_ID=
echo "IMAGE_ID=\"${IMAGE_NAME}\"" >> /usr/lib/os-release
echo "IMAGE_VERSION=\"${VERSION}\"" >> /usr/lib/os-release

# Fix issues caused by ID no longer being fedora
sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg

echo "::endgroup::"
echo "Image ID successfully applied!"
