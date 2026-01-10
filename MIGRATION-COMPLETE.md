# Kernel Build System Migration - Complete

## Summary

Successfully migrated the kernel build system from `snapmaker-u1-custom-kernel` to `base-debian-os` project following the approved migration plan.

## Changes Made

### New Files Created

#### Scripts (in `scripts/`)
1. **clone-rockchip-kernel.sh** - Clones/updates Rockchip kernel source
   - Accepts kernel version (6.1 or 6.6)
   - Handles both initial clone and updates
   - Uses `--depth=1` for efficiency

2. **kernel-config.sh** - Centralized kernel configuration
   - Defines 4 build profiles (basic, basic-devel, extended, extended-devel)
   - Maps kernel versions to git branches
   - Validation functions

3. **build-kernel.sh** - Main kernel build orchestrator
   - Converts Makefile logic to Bash following debootstrap.sh patterns
   - Handles: version patching, DTS injection, config application, module patching, FIT image creation
   - Process-isolated temp directories with cleanup trap

4. **launch-qemu.sh** - QEMU test launcher
   - Launches ARM64 QEMU with PL011 console
   - Supports additional QEMU arguments

#### Integration Files
5. **packages/u1-trixie.d/50-install-kernel.sh** - Rootfs kernel installer
   - Installs kernel Image, DTB, and patched modules during chroot phase
   - Auto-detects kernel version
   - Runs depmod

#### Container Files
6. **.github/dev/kernel-build.Dockerfile** - Kernel build container
   - Based on Ubuntu 22.04
   - ARM64 cross-compilation toolchain
   - Kernel build dependencies (bison, flex, libssl-dev, etc.)
   - FIT image tools (u-boot-tools, lz4)
   - ccache support

#### Documentation
7. **kernel/README.md** - Comprehensive kernel build guide
   - Quick start examples
   - Profile descriptions
   - Directory structure
   - Troubleshooting

### Files Modified

1. **dev.sh** - Enhanced container selection
   - Auto-detects kernel vs rootfs builds from script path
   - Routes to appropriate container (kernel-build or rootfs)
   - Kernel builds use ccache volume
   - Rootfs builds use privileged mode

2. **.github/workflows/build.yaml** - Parallel build workflow
   - Added `build-kernel` job with matrix strategy
   - Builds all 8 kernel variants (2 versions × 4 profiles)
   - Parallel execution with rootfs build
   - Uploads kernel artifacts

3. **.gitignore** - Added kernel artifacts
   - kernel/rockchip-kernel/
   - *.img, *.lz4, *.dtb, *.ko

4. **README.md** - Updated with kernel build instructions
   - Quick start for both rootfs and kernel
   - Profile descriptions
   - Links to kernel/README.md

### Files Copied (from source project)

Copied from `snapmaker-u1-custom-kernel/` to `base-debian-os/kernel/`:

1. **config/** - Kernel configuration files
   - stock.config
   - kernel-makefile-6.1.118.patch
   - kernel-makefile-6.6.118.patch

2. **dts/** - Device tree sources
   - rk3562-snapmaker-u1-stock.dts

3. **dump-original-kernel/** - Stock kernel artifacts
   - modules/chsc6540.ko, io_manager.ko
   - resource.img
   - fdt.dtb, fdt.dts
   - ANALYSIS.md

4. **boot.its.template** - FIT image template

### Source Project - Unchanged

✅ No files modified or deleted in `snapmaker-u1-custom-kernel/` as requested

## Directory Structure (base-debian-os)

```
base-debian-os/
├── .github/
│   ├── dev/
│   │   ├── Dockerfile                    # Rootfs build container
│   │   └── kernel-build.Dockerfile       # [NEW] Kernel build container
│   └── workflows/
│       └── build.yaml                     # [MODIFIED] Added kernel job
├── kernel/                                # [NEW DIRECTORY]
│   ├── README.md                          # [NEW] Kernel docs
│   ├── boot.its.template                  # [COPIED]
│   ├── config/                            # [COPIED]
│   │   ├── stock.config
│   │   ├── kernel-makefile-6.1.118.patch
│   │   └── kernel-makefile-6.6.118.patch
│   ├── dts/                               # [COPIED]
│   │   └── rk3562-snapmaker-u1-stock.dts
│   └── dump-original-kernel/              # [COPIED]
│       ├── modules/
│       ├── resource.img
│       └── ...
├── packages/
│   └── u1-trixie.d/
│       └── 50-install-kernel.sh           # [NEW] Kernel installer
├── scripts/
│   ├── debootstrap.sh                     # [UNCHANGED]
│   ├── clone-rockchip-kernel.sh           # [NEW]
│   ├── kernel-config.sh                   # [NEW]
│   ├── build-kernel.sh                    # [NEW]
│   └── launch-qemu.sh                     # [NEW]
├── dev.sh                                 # [MODIFIED] Container selection
├── .gitignore                             # [MODIFIED] Kernel artifacts
└── README.md                              # [MODIFIED] Kernel docs
```

## Build Profiles

All 4 profiles from the original project preserved:

| Profile          | Description                              | Config Fragment                    |
|------------------|------------------------------------------|------------------------------------|
| basic            | Minimal hardware boot                    | (stock config only)                |
| basic-devel      | Basic + debugging                        | +DEBUG_INFO +DEBUG_KERNEL          |
| extended         | Basic + Docker/QEMU                      | +containers +virtio +macvlan       |
| extended-devel   | Extended + debugging                     | +containers +virtio +macvlan +debug|

## Kernel Versions

Both versions supported:

- **6.1** → `linux-6.1-stan-rkr1` branch
- **6.6** → `linux-6.6-stan-rkr1` branch

## Workflow Integration

### Local Development
```bash
# Clone kernel (once)
./dev.sh ./scripts/clone-rockchip-kernel.sh 6.1

# Build kernel
./dev.sh ./scripts/build-kernel.sh 6.1 extended-devel output/kernel.img

# Test in QEMU
./dev.sh ./scripts/launch-qemu.sh output/kernel.img

# Build rootfs
./dev.sh ./scripts/debootstrap.sh trixie packages/u1-trixie output/rootfs.tgz
```

### CI/CD
GitHub Actions workflow builds:
- 8 kernel variants (2 versions × 4 profiles) in parallel
- 1 rootfs tarball
- All tagged with `YYYYMMDD-{git-sha}`
- Released as artifacts

## Testing

To verify the migration:

1. **Clone kernel source:**
   ```bash
   ./dev.sh ./scripts/clone-rockchip-kernel.sh 6.1
   ```

2. **Build extended-devel kernel:**
   ```bash
   mkdir -p output
   ./dev.sh ./scripts/build-kernel.sh 6.1 extended-devel output/test-kernel.img
   ```

3. **Test in QEMU:**
   ```bash
   ./dev.sh ./scripts/launch-qemu.sh output/test-kernel.img
   ```

4. **Verify build artifacts:**
   - output/test-kernel.img (FIT image)
   - tmp/kernel-*/arch/arm64/boot/Image
   - tmp/kernel-*/modules/*.ko

## Next Steps

1. Test kernel build in CI/CD (push to trigger workflow)
2. Verify all 8 kernel variants build successfully
3. Test rootfs integration (kernel artifacts mounted during debootstrap)
4. Consider adding kernel release artifacts to GitHub releases

## Migration Checklist

- ✅ Create kernel/ directory structure
- ✅ Copy config/, dts/, dump-original-kernel/, boot.its.template
- ✅ Create clone-rockchip-kernel.sh
- ✅ Create kernel-config.sh (profile definitions)
- ✅ Create build-kernel.sh (Makefile → Bash conversion)
- ✅ Create launch-qemu.sh
- ✅ Create 50-install-kernel.sh (rootfs integration)
- ✅ Create kernel-build.Dockerfile
- ✅ Update dev.sh (container selection)
- ✅ Update .github/workflows/build.yaml (parallel kernel job)
- ✅ Update .gitignore (kernel artifacts)
- ✅ Update README.md (kernel build docs)
- ✅ Create kernel/README.md (detailed guide)
- ✅ No modifications to source project

## Notes

- Source project (`snapmaker-u1-custom-kernel`) remains unchanged and can be archived
- All kernel build logic preserved from original Makefile
- Scripts follow base-debian-os patterns (set -e, cleanup traps, temp dirs)
- Container selection is automatic based on script path
- ccache volume shared across kernel builds for faster iteration
- Module patching (vermagic replacement) preserved for chsc6540 and io_manager
