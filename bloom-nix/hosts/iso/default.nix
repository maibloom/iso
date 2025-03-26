# ISO-specific configuration for Bloom Nix - Simplified version
{ config, pkgs, lib, ... }:

{
  # ISO-specific configuration
  isoImage = {
    # Set ISO filename and volume ID
    isoName = lib.mkForce "bloom-nix.iso";
    volumeID = lib.mkForce "BLOOM_NIX";

    # Make the ISO bootable via both BIOS and UEFI
    makeEfiBootable = true;
    makeUsbBootable = true;

    # Use mkDefault for the menu label so flake.nix can override it
    appendToMenuLabel = lib.mkDefault " Live";

    # Compression settings
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

  # Add disk utilities for the installation process
  environment.systemPackages = with pkgs; [
    # Disk utilities needed by the installer
    gparted
    parted
    ntfs3g
    dosfstools
    e2fsprogs
    btrfs-progs
    xfsprogs
    cryptsetup
    lvm2

    # Other useful utilities
    firefox
    git
    wget
    curl
    htop
  ];

  # Enable the needed polkit rules for disk mounting and system installation
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("wheel") &&
        (
          action.id.indexOf("org.freedesktop.udisks2.") == 0 ||
          action.id.indexOf("org.freedesktop.login1.") == 0 ||
          action.id.indexOf("org.freedesktop.systemd1.") == 0
        )
      ) {
        return polkit.Result.YES;
      }
    });
  '';
}
