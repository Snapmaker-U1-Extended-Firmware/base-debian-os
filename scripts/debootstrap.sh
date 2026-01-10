#!/bin/bash

set -e

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <suite> <packages-file> <out.tgz>"
  echo ""
  echo "Arguments:"
  echo "  suite           Debian suite (e.g., trixie, bookworm, bullseye)"
  echo "  packages-file   Path to file containing package list"
  echo "  out.tgz         Output tarball path"
  echo ""
  echo "Example:"
  echo "  $0 trixie debian-Packages debian-rootfs-trixie.tgz"
  exit 1
fi

SUITE="$1"
PACKAGES_FILE="$2"
OUTPUT_TARBALL="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCH=arm64
MIRROR="https://deb.debian.org/debian"
TMP_DIR="${REPO_ROOT}/tmp"
ROOTFS_DIR="${TMP_DIR}/rootfs-$$"

cleanup() {
  if [[ -d "$ROOTFS_DIR" ]]; then
    echo ">> Cleaning up temporary rootfs..."
    rm -rf "$ROOTFS_DIR"
  fi
}

trap cleanup EXIT INT TERM

if [[ ! -f "$PACKAGES_FILE" ]]; then
  echo "Error: Package list file not found: $PACKAGES_FILE"
  exit 1
fi

PACKAGES=$(cat "$PACKAGES_FILE" | grep -v '^#' | grep -v '^$' | tr '\n' ',' | sed 's/,$//')

if [[ -z "$PACKAGES" ]]; then
  echo "Error: No packages found in $PACKAGES_FILE"
  exit 1
fi

echo ">> Creating temporary directory..."
mkdir -p "$TMP_DIR"

OUTPUT_TARBALL="$(cd "$(dirname "$OUTPUT_TARBALL")" 2>/dev/null && pwd || mkdir -p "$(dirname "$OUTPUT_TARBALL")" && cd "$(dirname "$OUTPUT_TARBALL")" && pwd)/$(basename "$OUTPUT_TARBALL")"

rm -rf "$ROOTFS_DIR"

echo ">> Bootstrapping Debian $SUITE for $ARCH..."
echo ">> Packages: $PACKAGES"

export APT_CONFIG=/dev/null
export DEBIAN_FRONTEND=noninteractive

if ! debootstrap \
  --arch="$ARCH" \
  --foreign \
  --include="$PACKAGES" \
  "$SUITE" \
  "$ROOTFS_DIR" \
  "$MIRROR"; then
  echo ">> Debootstrap failed! Log contents:"
  cat "$ROOTFS_DIR/debootstrap/debootstrap.log" 2>/dev/null || echo "No log file found"
  exit 1
fi

echo ">> Disabling apt proxy auto-detection..."
mkdir -p "$ROOTFS_DIR/etc/apt/apt.conf.d"
cat > "$ROOTFS_DIR/etc/apt/apt.conf.d/99no-proxy-autodetect" <<'EOF'
Acquire::http::Proxy-Auto-Detect "";
Acquire::https::Proxy-Auto-Detect "";
EOF

echo ">> Running second stage bootstrap..."
if ! chroot "$ROOTFS_DIR" /debootstrap/debootstrap --second-stage; then
  echo ">> Second stage bootstrap failed! Log contents:"
  cat "$ROOTFS_DIR/debootstrap/debootstrap.log" 2>/dev/null || echo "No log file found"
  exit 1
fi

echo ">> Cleaning up..."
rm -rf "$ROOTFS_DIR/debootstrap"
rm -rf "$ROOTFS_DIR/var/cache/apt/archives/"*.deb
rm -rf "$ROOTFS_DIR/var/lib/apt/lists/"*
rm -rf "$ROOTFS_DIR/tmp/"*
rm -f "$ROOTFS_DIR/etc/apt/apt.conf.d/99no-proxy-autodetect"

echo ">> Removing system-specific customizations..."
rm -f "$ROOTFS_DIR/etc/ssh/ssh_host_"*
rm -f "$ROOTFS_DIR/etc/machine-id"
rm -f "$ROOTFS_DIR/var/lib/dbus/machine-id"
rm -f "$ROOTFS_DIR/etc/hostname"
rm -rf "$ROOTFS_DIR/var/log/"*
rm -rf "$ROOTFS_DIR/var/tmp/"*
rm -f "$ROOTFS_DIR/root/.bash_history"
rm -f "$ROOTFS_DIR/root/.ssh/known_hosts"

echo ">> Creating tarball: $OUTPUT_TARBALL..."
tar czf "$OUTPUT_TARBALL" -C "$ROOTFS_DIR" .

TARBALL_SIZE=$(du -h "$OUTPUT_TARBALL" | cut -f1)
echo ">> Bootstrap complete!"
echo ">> Output: $OUTPUT_TARBALL ($TARBALL_SIZE)"
