#!/usr/bin/env bash

# Clear the terminal
clear

# Update the flake to the latest version
nix-channel --update
nix flake update

# Build the ISO
if nix build .#nixosConfigurations.bloomNix.config.system.build.isoImage; then
  # Find the generated ISO file
  ISO_PATH=$(find result/iso -name "*.iso" | head -n 1)

  # Check if the ISO was found
  if [[ -f "$ISO_PATH" ]]; then
    echo "ISO found at $ISO_PATH. Launching QEMU..."
    # Launch QEMU with the generated ISO
    qemu-system-x86_64 -cdrom "$ISO_PATH" -boot d -m 23G -smp 12
  else
    echo "ISO not found. Please check the build output for errors."
  fi
else
  echo "Build failed. Please check the build output for errors."
fi
