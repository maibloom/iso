#!/bin/bash
# Script to build the Bloom Nix ISO

# Ensure the script exits if any command fails

clear


set -e

echo "Building Bloom Nix ISO..."

# Build the ISO using nix-build
nix-build '<nixpkgs/nixos>' \
  -A config.system.build.isoImage \
  -I nixos-config=./configuration.nix

# Get the ISO path
ISO_PATH=$(readlink -f result/iso/*.iso)

echo "ISO successfully built at: $ISO_PATH"
echo "You can burn this to a USB drive with:"
echo "  sudo dd if=$ISO_PATH of=/dev/sdX bs=4M status=progress"
echo "  (Replace sdX with your USB device, BE CAREFUL!)"


qemu-system-x86_64 -cdrom result/iso/* -boot d 