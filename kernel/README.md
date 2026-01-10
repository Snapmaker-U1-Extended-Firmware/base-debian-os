# Snapmaker U1 Custom Kernel

This directory contains the custom kernel build system for Snapmaker U1.

## Quick Start

### Clone Kernel Source
```bash
./dev.sh ./scripts/clone-rockchip-kernel.sh 6.1
```

### Build Kernel
```bash
./dev.sh ./scripts/build-kernel.sh 6.1 extended-devel output/kernel.img
```

### Test in QEMU
```bash
./dev.sh ./scripts/launch-qemu.sh output/kernel.img
```

## Build Profiles

Four profiles are available, each building on the previous:

### basic
- Minimal kernel for hardware boot
- Stock Snapmaker U1 configuration
- No additional features

### basic-devel
- `basic` + debugging support
- CONFIG_DEBUG_INFO=y
- CONFIG_DEBUG_KERNEL=y
- CONFIG_DEBUG_FS=y

### extended
- `basic` + container/virtualization support
- Docker/Podman support (namespaces, cgroups, veth, bridge, overlay fs)
- QEMU support (virtio drivers, PL011 serial, PL031 RTC)
- MACVLAN networking

### extended-devel
- `extended` + debugging support
- Full debugging + containers + virtualization

## Kernel Versions

Two kernel versions are supported:

- **6.1** - rockchip-linux/kernel.git branch `linux-6.1-stan-rkr1`
- **6.6** - rockchip-linux/kernel.git branch `linux-6.6-stan-rkr1`

## Directory Structure

```
kernel/
├── boot.its.template       # FIT image template
├── config/                 # Kernel configuration
│   ├── stock.config        # Base Snapmaker U1 config
│   ├── kernel-makefile-6.1.118.patch
│   └── kernel-makefile-6.6.118.patch
├── dts/                    # Device tree sources
│   └── rk3562-snapmaker-u1-stock.dts
└── dump-original-kernel/   # Stock kernel artifacts
    ├── modules/            # Proprietary modules (chsc6540, io_manager)
    └── resource.img        # Rockchip resource partition
```

## Build Scripts

### scripts/clone-rockchip-kernel.sh
Clones the Rockchip kernel source. Run this once before building.

**Usage:**
```bash
./dev.sh ./scripts/clone-rockchip-kernel.sh <kernel-version>
```

### scripts/build-kernel.sh
Main kernel build orchestrator.

**Usage:**
```bash
./dev.sh ./scripts/build-kernel.sh <kernel-version> <build-profile> <output.img>
```

**Process:**
1. Patches kernel version
2. Copies device tree
3. Configures kernel with stock.config
4. Applies profile-specific config fragments
5. Builds kernel, DTB, and modules
6. Patches proprietary modules
7. Creates FIT boot image

### scripts/launch-qemu.sh
Launches QEMU with the built kernel.

**Usage:**
```bash
./dev.sh ./scripts/launch-qemu.sh <boot.img> [qemu-args...]
```

**Features:**
- ARM64 Cortex-A72 emulation
- 2GB RAM
- PL011 UART console
- Serial output to stdio

**Exit:** Press `Ctrl-A X`

### scripts/kernel-config.sh
Centralized configuration (sourced by other scripts).

**Defines:**
- `KERNEL_PROFILES` - Associative array of config fragments
- `get_kernel_branch()` - Maps version to git branch
- `validate_profile()` - Validates profile names

## Integration with Rootfs

The kernel can be integrated into the rootfs build:

### Manual Integration
```bash
# Build kernel
./dev.sh ./scripts/build-kernel.sh 6.1 extended output/kernel.img

# Build rootfs with kernel artifacts mounted
# (see packages/u1-trixie.d/50-install-kernel.sh)
```

### CI/CD Integration
The GitHub workflow builds kernels in parallel with the rootfs. See [.github/workflows/build.yaml](.github/workflows/build.yaml).

## Development

### Adding New Config Options

Edit [scripts/kernel-config.sh](../scripts/kernel-config.sh):

```bash
KERNEL_PROFILES["my-profile"]="CONFIG_MY_OPTION=y CONFIG_ANOTHER=m"
```

### Modifying Device Tree

Edit [dts/rk3562-snapmaker-u1-stock.dts](dts/rk3562-snapmaker-u1-stock.dts).

### Debugging Builds

Use the `-devel` profiles for debug symbols:
```bash
./dev.sh ./scripts/build-kernel.sh 6.1 basic-devel output/kernel-debug.img
```

## Troubleshooting

### Kernel source not found
```
Error: Kernel source not found at kernel/rockchip-kernel
Run: ./dev.sh ./scripts/clone-rockchip-kernel.sh 6.1
```

**Solution:** Clone the kernel source first.

### Build failures
Check [tmp/kernel-$$](../tmp/) for build logs. The build directory persists on error.

### QEMU doesn't boot
Ensure you're using an `extended` or `extended-devel` profile (requires virtio drivers).

## References

- [Rockchip Kernel Source](https://github.com/rockchip-linux/kernel)
- [Snapmaker U1 Documentation](https://wiki.snapmaker.com/en/snapmaker_u1)
- [U-Boot FIT Image Format](https://github.com/u-boot/u-boot/blob/master/doc/uImage.FIT/howto.txt)
