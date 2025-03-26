#!/usr/bin/env bash
# Build script for Bloom Nix distribution

set -e # Exit on error

echo "===== Building Bloom Nix Distribution ====="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root to ensure proper permissions"
   echo "Please run with: sudo $0"
   exit 1
fi

clear

# Ensure we have the right channel
echo "Checking NixOS channel..."
nix-channel --list | grep -q "nixos" || nix-channel --add https://nixos.org/channels/nixos-23.11 nixos
nix-channel --update

# Build the ISO image
echo "Building Bloom Nix ISO image..."
nix-build default.nix -A iso

# Copy the result to a more accessible location
echo "Copying ISO to the current directory..."
ISO_PATH=$(readlink -f result/iso/*.iso)
ISO_NAME=$(basename "$ISO_PATH")
cp "$ISO_PATH" "./$ISO_NAME"

echo "===== Build Complete ====="
echo "ISO image created at: ./$ISO_NAME"
echo "You can write this to a USB drive with:"
echo "sudo dd if=./$ISO_NAME of=/dev/sdX bs=4M status=progress oflag=sync"
echo "Replace sdX with your USB drive device (be careful!)"

# Provide option to test in QEMU
read -p "Would you like to test the ISO in QEMU? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting QEMU with the ISO..."
    qemu-system-x86_64 -enable-kvm -m 4G -smp 4 -cdrom "$ISO_NAME" -boot d
fi
