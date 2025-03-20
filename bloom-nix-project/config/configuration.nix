# config/build-iso.nix
# Configuration for building the Bloom Nix live ISO image
{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowBroken = true;

  imports = [
    # Base ISO configuration from nixpkgs
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix>

    # Import shared configuration
    ./modules/shared-config.nix

    # Import branding and desktop environment
    ../modules/branding
    ../modules/desktop/xfce.nix

    # Import hardware support
    ../modules/hardware-support.nix
  ];

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

  # Auto-login for live environment
  services.xserver.displayManager = lib.mkForce {
    autoLogin = {
      enable = true;
      user = "nixos";
    };
    defaultSession = "plasma";

    # Enable SDDM and disable LightDM
    sddm.enable = true;
    lightdm.enable = false;
  };

  # Boot settings
  boot.loader.timeout = lib.mkForce 5;
  boot.loader.grub.timeoutStyle = lib.mkForce "menu";
  boot.plymouth.enable = true;  # Enable Plymouth for a nicer boot experience
  boot.supportedFilesystems = lib.mkForce [ "vfat" "ext4" "btrfs" "xfs" "ntfs" ];
  isoImage.squashfsCompression = "gzip";

  # Ensure better hardware support
  hardware.enableAllFirmware = true;

  # System state version
  system.stateVersion = "23.11";
}
