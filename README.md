# Debian Base OS Builder

This repository builds a minimal Debian rootfs tarball for use in embedded systems.

## Files

- `scripts/debootstrap.sh` - Main script that creates the Debian rootfs
- `packages/` - List of packages for debootstrap

## Local Build

```bash
./dev.sh ./scripts/debootstrap.sh <suite> <packages-file> <out.tgz>
```

Example:

```bash
./dev.sh ./scripts/debootstrap.sh trixie packages/u1-trixie debian-rootfs-trixie.tgz
```

## Requirements

- Docker

## License

GPLv3
