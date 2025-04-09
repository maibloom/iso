#!/usr/bin/env bash
set -e

clear

# Clean previous builds
rm -rf result

# Build ISO
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=./iso.nix --show-trace

# Test in QEMU (optional)
qemu-system-x86_64 -enable-kvm -m 4096 -cdrom ./result/iso/custom-distro.iso
