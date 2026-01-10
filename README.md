# Debian Base OS Builder

This repository builds a minimal Debian rootfs tarball and custom kernel for Snapmaker U1 3D Printer.

## Components

### Rootfs Builder

- `scripts/debootstrap.sh` - Main script that creates the Debian rootfs
- `packages/` - Package lists for debootstrap
- `packages/u1-trixie.d/` - Post-install scripts (including kernel integration)

### Kernel Builder

- `scripts/clone-rockchip-kernel.sh` - Clone Rockchip kernel source
- `scripts/build-kernel.sh` - Build custom kernel with profiles
- `scripts/launch-qemu.sh` - Test kernel in QEMU
- `kernel/` - Kernel configuration, DTS, modules, and build artifacts

See [kernel/README.md](kernel/README.md) for detailed kernel build documentation.

## Prerequisites

**First time setup:** Extract proprietary modules and resources from stock firmware:

```bash
# Download stock firmware and build extraction tools
./dev.sh make firmware tools

# Extract proprietary modules (chsc6540.ko, io_manager.ko) and resource.img
./dev.sh make extract-proprietary
```

This downloads the stock U1 firmware (~200MB) and extracts:
- `tmp/proprietary/modules/` - Proprietary kernel modules
- `tmp/proprietary/resource.img` - Boot resources (logo, etc.)

These files are in tmp/ (excluded from git) and are required for kernel builds.

## Quick Start

### Build Everything (Kernel + Rootfs)

```bash
# One command to build kernel and rootfs together
./dev.sh ./scripts/build-all.sh extended

# Or with specific kernel version
./dev.sh ./scripts/build-all.sh extended-devel 6.1
```

This builds the kernel and integrates it into the rootfs tarball.

### Build Kernel Only

```bash
# Clone kernel source (once)
./dev.sh ./scripts/clone-rockchip-kernel.sh 6.1

# Build kernel with extended profile (Docker + QEMU support)
./dev.sh ./scripts/build-kernel.sh 6.1 extended-devel output/kernel.img

# Test in QEMU
./dev.sh ./scripts/launch-qemu.sh output/kernel.img
```

### Build Rootfs Only

```bash
# Builds rootfs with kernel from tmp/kernel-artifacts/ (if available)
./dev.sh ./scripts/debootstrap.sh trixie packages/u1-trixie output/debian-rootfs-trixie.tgz
```

If you previously built a kernel, it will be included. Otherwise, rootfs builds without custom kernel.

## Kernel Build Profiles

Four profiles are available:

- **basic** - Minimal hardware boot
- **basic-devel** - Basic + debugging
- **extended** - Basic + Docker/QEMU support
- **extended-devel** - Extended + debugging

See [kernel/README.md](kernel/README.md) for details.

## Requirements

- Docker

## CI/CD

GitHub Actions builds both rootfs and kernels in parallel. See [.github/workflows/build.yaml](.github/workflows/build.yaml).

Artifacts are published as releases with version tag `YYYYMMDD-{git-sha}`.

## License

GPLv3
