#!/usr/bin/env bash
# Simple Bloom Nix build and test script

clear

# Create log file
LOG_FILE="bloom-build.log"
echo "=== Bloom Nix Build Log $(date) ===" > "$LOG_FILE"

# Function to log messages
log() {
  echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Build the ISO
log "Starting Bloom Nix build..."
nix-build default.nix -A iso 2>&1 | tee -a "$LOG_FILE"

# Check if build was successful
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  log "Build failed! Check log for details."
  exit 1
fi

# Get the ISO path
ISO_PATH=$(readlink -f result/iso/*.iso)
ISO_NAME=$(basename "$ISO_PATH")

# Log success
log "Build successful! ISO created at: $ISO_PATH"

# Launch in QEMU
log "Starting QEMU with the ISO..."
qemu-system-x86_64 -enable-kvm -m 4G -smp 4 -cdrom "$ISO_PATH" -boot d -display gtk 2>&1 | tee -a "$LOG_FILE"

log "Testing completed."
echo "All output has been saved to $LOG_FILE"
