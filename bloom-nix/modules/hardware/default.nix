# ISO-specific configuration for Bloom Nix - Flake compatible
{ config, pkgs, lib, inputs, outputs, ... }:

{
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
    squashfsCompression = "gzip";
  };

  # Live environment user configuration
  users.users.nixos = {
    isNormalUser = true;
    description = "Bloom Nix Live User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    # No password for live environment
    initialPassword = "";
  };

  # Allow sudo without password for live environment
  security.sudo.wheelNeedsPassword = false;

  # Add the Bloom installer to the system
  environment.systemPackages = with pkgs; [
    # Add any other ISO-specific packages here
    gparted
    parted
    ntfs3g
    dosfstools
  ];

  # Automatically log in the live user
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Enable SSH for remote installation assistance (optional)
  # services.openssh.enable = true;
  
  # Import appropriate modules for ISO - flake style
  imports = [
    # You can specify additional imports here if needed
  ];
}