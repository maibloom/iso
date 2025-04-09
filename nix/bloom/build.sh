#!/usr/bin/env bash

clear

# Build ISO
nix-build default.nix -A iso || exit 1

# Get ISO path
ISO_PATH=$(readlink -f result/iso/*.iso)
if [ -z "$ISO_PATH" ]; then
  echo "Error: ISO not found in result/iso!"
  exit 1
fi

# Launch QEMU
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -smp 4 \
  -cdrom "$ISO_PATH" \
  -boot d \
  -display gtk \
  -monitor stdio
