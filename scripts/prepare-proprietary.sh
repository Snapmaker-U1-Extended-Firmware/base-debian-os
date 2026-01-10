#!/usr/bin/env bash
# Download stock firmware and extract proprietary files
# Based on SnapmakerU1-Extended-Firmware extraction process

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

FIRMWARE_FILE="U1_1.0.0.158_20251230140122_upgrade.bin"
FIRMWARE_SHA256="e1079ed43d41fff7411770d7bbc3857068bd4b1d3570babf07754e2dd9cbfc2e"
FIRMWARE_URL="https://public.resource.snapmaker.com/firmware/U1/$FIRMWARE_FILE"

FIRMWARE_PATH="$ROOT_DIR/tmp/firmware/$FIRMWARE_FILE"
EXTRACT_DIR="$ROOT_DIR/tmp/extracted"
DEST_MODULES="$ROOT_DIR/tmp/proprietary/modules"
DEST_RESOURCE="$ROOT_DIR/tmp/proprietary/resource.img"

echo "========================================="
echo "Preparing proprietary files"
echo "========================================="

# Check if already extracted
if [[ -f "$DEST_RESOURCE" ]] && [[ -f "$DEST_MODULES/chsc6540.ko" ]] && [[ -f "$DEST_MODULES/io_manager.ko" ]]; then
    echo ">> Proprietary files already present. Skipping extraction."
    exit 0
fi

# Download firmware if needed
if [[ ! -f "$FIRMWARE_PATH" ]]; then
    echo ">> Downloading stock firmware..."
    mkdir -p "$(dirname "$FIRMWARE_PATH")"
    if command -v wget &> /dev/null; then
        wget -O "$FIRMWARE_PATH.tmp" "$FIRMWARE_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$FIRMWARE_PATH.tmp" "$FIRMWARE_URL"
    else
        echo "Error: Neither wget nor curl found. Cannot download firmware."
        exit 1
    fi
    
    echo ">> Verifying firmware checksum..."
    echo "$FIRMWARE_SHA256  $FIRMWARE_PATH.tmp" | sha256sum -c --quiet
    mv "$FIRMWARE_PATH.tmp" "$FIRMWARE_PATH"
    echo ">> Firmware downloaded: $FIRMWARE_PATH"
else
    echo ">> Using cached firmware: $FIRMWARE_PATH"
fi

# Build extraction tools if needed
if [[ ! -f "$ROOT_DIR/tools/upfile/upfile" ]] || [[ ! -f "$ROOT_DIR/tools/rk2918_tools/afptool" ]]; then
    echo ">> Building extraction tools..."
    make -C "$ROOT_DIR/tools/upfile" -j"$(nproc)"
    make -C "$ROOT_DIR/tools/rk2918_tools" -j"$(nproc)"
fi

# Extract firmware
echo ">> Extracting stock firmware to $EXTRACT_DIR..."
"$SCRIPT_DIR/extract_squashfs.sh" "$FIRMWARE_PATH" "$EXTRACT_DIR"

# Extract boot.img components
echo ">> Extracting boot.img components..."
BOOT_IMG="$EXTRACT_DIR/rk-unpacked/boot.img"
if [[ ! -f "$BOOT_IMG" ]]; then
    echo "Error: boot.img not found at $BOOT_IMG"
    exit 1
fi

BOOT_EXTRACT="$EXTRACT_DIR/boot"
mkdir -p "$BOOT_EXTRACT"

dumpimage -T flat_dt -p 0 -o "$BOOT_EXTRACT/fdt.dtb" "$BOOT_IMG"
dumpimage -T flat_dt -p 1 -o "$BOOT_EXTRACT/kernel.lz4" "$BOOT_IMG"
dumpimage -T flat_dt -p 2 -o "$BOOT_EXTRACT/resource.img" "$BOOT_IMG"

# Extract modules from rootfs
MODULES_SRC="$EXTRACT_DIR/rootfs/usr/lib/modules"
if [[ ! -d "$MODULES_SRC" ]]; then
    echo "Error: Modules not found at $MODULES_SRC"
    exit 1
fi

# Install proprietary files
echo ">> Installing proprietary files to tmp/proprietary/..."
mkdir -p "$DEST_MODULES"
cp "$BOOT_EXTRACT/resource.img" "$DEST_RESOURCE"
cp "$MODULES_SRC/chsc6540.ko" "$DEST_MODULES/"
cp "$MODULES_SRC/io_manager.ko" "$DEST_MODULES/"

echo ""
echo "========================================="
echo "Proprietary files extracted:"
echo "  - $DEST_RESOURCE"
echo "  - $DEST_MODULES/chsc6540.ko"
echo "  - $DEST_MODULES/io_manager.ko"
echo ""
echo "Note: These files are in tmp/ and excluded from git"
echo "========================================="
