#!/bin/bash
set -euo pipefail

# Check if qemu-system-x86_64 is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
  echo "Error: qemu-system-x86_64 is not installed. Please install QEMU."
  exit 1
fi

# Prompt the user for memory and CPU allocation
read -rp "Enter the amount of memory to allocate (in MB): " memory
read -rp "Enter the number of CPU cores to allocate: " cpus

# Validate that inputs are numeric
if ! [[ "$memory" =~ ^[0-9]+$ ]] || ! [[ "$cpus" =~ ^[0-9]+$ ]]; then
  echo "Error: Memory and CPU values must be numeric."
  exit 1
fi

# Find the ISO file in results/iso/ using a wildcard
iso_file=$(ls results/iso/* 2>/dev/null | head -n 1)
if [ -z "$iso_file" ]; then
  echo "Error: No ISO file found in results/iso/"
  exit 1
fi

echo "Using ISO file: $iso_file"
echo "Starting QEMU with $memory MB memory and $cpus CPU core(s)..."

# Launch QEMU to boot the ISO
qemu-system-x86_64 -m "$memory" -smp "$cpus" -cdrom "$iso_file" -boot d
