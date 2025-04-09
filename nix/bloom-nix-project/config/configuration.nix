# config/build-iso.nix
# Configuration for building the Bloom Nix live ISO image
{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowBroken = true;

  # ISO-specific configuration
  isoImage = {
    # Set ISO filename and volume ID
    isoName = lib.mkForce "bloom-nix.iso";
    volumeID = lib.mkForce "BLOOM_NIX";

    # Make the ISO bootable via both BIOS and UEFI
    makeEfiBootable = true;
    makeUsbBootable = true;

    # Add build information to the ISO label
    appendToMenuLabel = " Live";
  };

  # Live environment user experience
  security.sudo.wheelNeedsPassword = false;

  isoImage.squashfsCompression = "gzip";

  # Ensure better hardware support
  hardware.enableAllFirmware = true;

  # System state version
  system.stateVersion = "23.11";
}
