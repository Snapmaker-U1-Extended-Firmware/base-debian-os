#!/bin/bash
set -e

# This script installs the custom Snapmaker U1 kernel into the rootfs
# Called during chroot phase of debootstrap

echo ">> Installing Snapmaker U1 custom kernel..."

# Kernel artifacts are expected to be mounted at /tmp/kernel-artifacts
# by the build orchestration script
KERNEL_ARTIFACTS="/tmp/kernel-artifacts"

if [[ ! -d "$KERNEL_ARTIFACTS" ]]; then
  echo "Warning: Kernel artifacts not found at $KERNEL_ARTIFACTS"
  echo "Skipping custom kernel installation."
  exit 0
fi

# Install kernel image
if [[ -f "$KERNEL_ARTIFACTS/Image" ]]; then
  echo ">> Installing kernel image..."
  install -m 0644 "$KERNEL_ARTIFACTS/Image" /boot/Image
fi

# Install device tree
if [[ -f "$KERNEL_ARTIFACTS/rk3562-snapmaker-u1-stock.dtb" ]]; then
  echo ">> Installing device tree..."
  install -m 0644 "$KERNEL_ARTIFACTS/rk3562-snapmaker-u1-stock.dtb" /boot/rk3562-snapmaker-u1.dtb
fi

# Install all kernel modules
if [[ -d "$KERNEL_ARTIFACTS/lib/modules" ]]; then
  echo ">> Installing kernel modules..."
  cp -r "$KERNEL_ARTIFACTS/lib/modules"/* /lib/modules/
  
  # Run depmod for each installed kernel version
  for kver in /lib/modules/*; do
    if [[ -d "$kver" ]]; then
      kver=$(basename "$kver")
      echo ">> Running depmod for $kver..."
      depmod -a "$kver" || true
    fi
  done
fi

echo ">> Kernel installation complete."
