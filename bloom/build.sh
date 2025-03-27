#!/usr/bin/env bash
# Enhanced build script for Bloom Nix with better error handling

set -e # Exit on error

LOG_FILE="build.log"
echo "" > "$LOG_FILE" # Clear log file

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "===== Building Bloom Nix Distribution ====="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log "This script must be run as root to ensure proper permissions"
   log "Please run with: sudo $0"
   exit 1
fi

# Ensure nix store is garbage collected for space
log "Cleaning nix store to ensure adequate space..."
nix-collect-garbage -d

# Ensure we have the right channel
log "Setting up NixOS channel..."
# nix-channel --remove nixos 2>/dev/null || true
# nix-channel --add https://nixos.org/channels/nixos-23.11 nixos
# nix-channel --update 2>>"$LOG_FILE"

# Create a deterministic build environment
log "Setting up build environment..."
export NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=./default.nix
export NIXOS_CONFIG=$(pwd)/default.nix

# Increase logging
export NIX_SHOW_STATS=1
export NIX_COUNT_CALLS=1

# Try to build with more conservative settings
log "Building Bloom Nix ISO image..."
nix-build default.nix -A iso \
    --option sandbox false \
    --option substitute true \
    --option build-cores 2 \
    --show-trace \
    --keep-going 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "Error occurred during the build process. Check $LOG_FILE for details."
    exit 1
fi

# Copy the result to a more accessible location
log "Copying ISO to the current directory..."
ISO_PATH=$(readlink -f result/iso/*.iso)
ISO_NAME=$(basename "$ISO_PATH")
cp "$ISO_PATH" "./$ISO_NAME" 2>>"$LOG_FILE"

log "===== Build Complete ====="
log "ISO image created at: ./$ISO_NAME"
log "You can write this to a USB drive with:"
log "sudo dd if=./$ISO_NAME of=/dev/sdX bs=4M status=progress oflag=sync"
log "Replace sdX with your USB drive device (be careful!)"

# Provide option to test in QEMU
read -p "Would you like to test the ISO in QEMU? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Starting QEMU with the ISO..."
    qemu-system-x86_64 -enable-kvm -m 4G -smp 4 -cdrom "$ISO_NAME" -boot d
fi
