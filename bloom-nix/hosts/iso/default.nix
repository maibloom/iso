# ISO-specific configuration for Bloom Nix - Flake compatible
{ config, pkgs, lib, ... }:

let
  # Helper function to find a terminal emulator
  # This tries different options in order of preference
  getTerminal =
    if pkgs ? kdePackages && pkgs.kdePackages ? konsole then "${lib.getBin pkgs.kdePackages.konsole}/bin/konsole"
    else if pkgs ? plasma5Packages && pkgs.plasma5Packages ? konsole then "${lib.getBin pkgs.plasma5Packages.konsole}/bin/konsole"
    else if pkgs ? konsole then "${lib.getBin pkgs.konsole}/bin/konsole"
    else "${lib.getBin pkgs.xterm}/bin/xterm";  # Fall back to xterm which always exists
in {
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
  environment.etc = lib.mkIf (config.services.xserver.enable or false) {
    "skel/Desktop/terminal.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Terminal
      Comment=Access the command line
      Exec=${getTerminal}
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

  # This makes the auto-login setting more robust by:
  # 1. Only adding services.displayManager if services.xserver.enable is true
  services = lib.mkIf (config.services.xserver.enable or false) {
    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };
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
}
