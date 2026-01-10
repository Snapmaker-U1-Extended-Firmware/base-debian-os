#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <kernel-profile> [kernel-version]"
  echo ""
  echo "Arguments:"
  echo "  kernel-profile   Kernel build profile (basic, basic-devel, extended, extended-devel)"
  echo "  kernel-version   Kernel version (default: 6.1)"
  echo ""
  echo "Example:"
  echo "  $0 extended"
  echo "  $0 extended-devel 6.1"
  exit 1
fi

KERNEL_PROFILE="$1"
KERNEL_VERSION="${2:-6.1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Generate version tag
VERSION="$(date +%Y%m%d)-$(git rev-parse --short HEAD 2>/dev/null || echo 'local')"

echo "=========================================="
echo "Building Snapmaker U1 Complete OS"
echo "=========================================="
echo "Kernel Profile:  $KERNEL_PROFILE"
echo "Kernel Version:  $KERNEL_VERSION"
echo "Build Version:   $VERSION"
echo "=========================================="
echo ""

# Clone kernel if needed
if [[ ! -d "$REPO_ROOT/kernel/rockchip-kernel/.git" ]]; then
  echo ">> Step 1/3: Cloning Rockchip kernel..."
  "$SCRIPT_DIR/clone-rockchip-kernel.sh" "$KERNEL_VERSION"
else
  echo ">> Step 1/3: Kernel source already cloned (skipping)"
fi

# Build kernel
echo ""
echo ">> Step 2/3: Building kernel ($KERNEL_PROFILE profile)..."
mkdir -p "$REPO_ROOT/output"
"$SCRIPT_DIR/build-kernel.sh" \
  "$KERNEL_VERSION" \
  "$KERNEL_PROFILE" \
  "$REPO_ROOT/output/kernel-${KERNEL_PROFILE}-${KERNEL_VERSION}-${VERSION}.img"

# Build rootfs
echo ""
echo ">> Step 3/3: Building Debian rootfs with kernel..."
"$SCRIPT_DIR/debootstrap.sh" \
  trixie \
  "$REPO_ROOT/packages/u1-trixie" \
  "$REPO_ROOT/output/debian-rootfs-trixie-${VERSION}.tgz"

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo "Artifacts:"
echo "  - output/kernel-${KERNEL_PROFILE}-${KERNEL_VERSION}-${VERSION}.img"
echo "  - output/kernel-${KERNEL_PROFILE}-${KERNEL_VERSION}-${VERSION}-vmlinuz"
echo "  - output/kernel-${KERNEL_PROFILE}-${KERNEL_VERSION}-${VERSION}.dtb"
echo "  - output/kernel-${KERNEL_PROFILE}-${KERNEL_VERSION}-${VERSION}.config"
echo "  - output/debian-rootfs-trixie-${VERSION}.tgz"
echo "=========================================="
