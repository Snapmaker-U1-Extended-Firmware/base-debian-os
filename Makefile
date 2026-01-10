include vars.mk

# ================= Configuration =================

KERNEL_VERSION ?= 6.1
BUILD_PROFILE ?= extended
OUTPUT_DIR ?= output

KERNEL_PROFILES := basic basic-devel extended extended-devel

# Generate version tag
GIT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo 'local')
VERSION := $(shell date +%Y%m%d)-$(GIT_SHA)

# Output files
KERNEL_IMG := $(OUTPUT_DIR)/kernel-$(BUILD_PROFILE)-$(KERNEL_VERSION)-$(VERSION).img
KERNEL_VMLINUZ := $(OUTPUT_DIR)/kernel-$(BUILD_PROFILE)-$(KERNEL_VERSION)-$(VERSION)-vmlinuz
KERNEL_DTB := $(OUTPUT_DIR)/kernel-$(BUILD_PROFILE)-$(KERNEL_VERSION)-$(VERSION).dtb
KERNEL_CONFIG := $(OUTPUT_DIR)/kernel-$(BUILD_PROFILE)-$(KERNEL_VERSION)-$(VERSION).config
KERNEL_MODULES := $(OUTPUT_DIR)/kernel-$(BUILD_PROFILE)-$(KERNEL_VERSION)-$(VERSION)-modules.tar.gz
ROOTFS_TGZ := $(OUTPUT_DIR)/debian-rootfs-trixie-$(VERSION).tgz

# ================= Help =================

.PHONY: help
help:
	@echo "Snapmaker U1 Custom OS Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make kernel PROFILE=<profile> [VERSION=<version>] [OUTPUT_DIR=<dir>]"
	@echo "  make rootfs [OUTPUT_DIR=<dir>]"
	@echo "  make all PROFILE=<profile> [VERSION=<version>] [OUTPUT_DIR=<dir>]"
	@echo "  make clean"
	@echo ""
	@echo "Kernel Profiles:"
	@echo "  basic          - Minimal hardware boot"
	@echo "  basic-devel    - Basic + debugging"
	@echo "  extended       - Basic + Docker/QEMU support"
	@echo "  extended-devel - Extended + debugging"
	@echo ""
	@echo "Variables:"
	@echo "  PROFILE        - Build profile (default: $(BUILD_PROFILE))"
	@echo "  VERSION        - Kernel version: 6.1 or 6.6 (default: $(KERNEL_VERSION))"
	@echo "  OUTPUT_DIR     - Output directory (default: $(OUTPUT_DIR))"
	@echo ""
	@echo "Examples:"
	@echo "  make kernel PROFILE=basic-devel"
	@echo "  make kernel PROFILE=extended VERSION=6.1"
	@echo "  make all PROFILE=extended-devel"
	@echo "  make rootfs"
	@echo ""
	@echo "Launch QEMU:"
	@echo "  make qemu PROFILE=extended-devel [VERSION=6.1]"

# ================= Kernel Build =================

.PHONY: kernel
kernel: $(KERNEL_IMG)

$(KERNEL_IMG): scripts/clone-rockchip-kernel.sh scripts/build-kernel.sh
	@echo "Building kernel $(KERNEL_VERSION) with profile $(BUILD_PROFILE)..."
ifeq ($(filter $(BUILD_PROFILE),$(KERNEL_PROFILES)),)
	@echo "Error: Invalid profile '$(BUILD_PROFILE)'"
	@echo "Available profiles: $(KERNEL_PROFILES)"
	@exit 1
endif
	@mkdir -p $(OUTPUT_DIR)
	@./scripts/clone-rockchip-kernel.sh $(KERNEL_VERSION)
	@./scripts/build-kernel.sh $(KERNEL_VERSION) $(BUILD_PROFILE) $(KERNEL_IMG)

# ================= Rootfs Build =================

.PHONY: rootfs
rootfs: $(ROOTFS_TGZ)

$(ROOTFS_TGZ): scripts/debootstrap.sh packages/u1-trixie
	@echo "Building Debian rootfs..."
	@mkdir -p $(OUTPUT_DIR)
	@./scripts/debootstrap.sh trixie packages/u1-trixie $(ROOTFS_TGZ)

# ================= Combined Build =================

.PHONY: all
all: kernel rootfs

# ================= QEMU Launch =================

.PHONY: qemu
qemu: $(KERNEL_IMG)
	@./scripts/launch-qemu.sh $(KERNEL_IMG)

# ================= Clean =================

.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)
	@rm -rf tmp/kernel-*
	@rm -rf tmp/rootfs-*
	@rm -rf tmp/kernel-artifacts
	@echo "Clean complete."

.PHONY: clean-all
clean-all: clean
	@echo "Cleaning kernel source..."
	@rm -rf kernel/rockchip-kernel
	@echo "Clean all complete."

# ================= Info =================

.PHONY: version
version:
	@echo "$(VERSION)"

.PHONY: profiles
profiles:
	@echo "Available kernel profiles:"
	@echo "  $(KERNEL_PROFILES)"

# ================= Firmware Extraction =================

.PHONY: tools
tools: tools/rk2918_tools tools/upfile

tools/%: FORCE
	make -C $@

.PHONY: firmware
firmware: firmware/$(FIRMWARE_FILE)

firmware/$(FIRMWARE_FILE):
	@mkdir -p firmware
	wget -O $@.tmp "https://public.resource.snapmaker.com/firmware/U1/$(FIRMWARE_FILE)"
	echo "$(FIRMWARE_SHA256)  $@.tmp" | sha256sum -c --quiet
	mv $@.tmp $@

.PHONY: extract
extract: firmware/$(FIRMWARE_FILE) tools
	./scripts/extract_squashfs.sh $< tmp/extracted

.PHONY: extract-proprietary
extract-proprietary: firmware/$(FIRMWARE_FILE) tools
	./scripts/extract-proprietary.sh

.PHONY: FORCE
FORCE:
