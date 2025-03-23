# ISO-specific configuration for Bloom Nix - Flake compatible
{ config, lib, pkgs, inputs, outputs, ... }:

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

  # Desktop shortcuts - create these in the appropriate location
  environment.etc = {

    "skel/Desktop/terminal.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Terminal
      Comment=Access the command line
      Exec=${lib.getBin pkgs.libsForQt5.konsole}/bin/konsole
      Icon=utilities-terminal
      Terminal=false
      Categories=System;
    '';
  };

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

  # Automatically log in the live user
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

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

  imports = [
    ../../modules/calamares
  ];

  services.calamares.enable = true;

}
