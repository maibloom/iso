{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix>

    ./configuration.nix
    ./shared-config.nix
    ./modules/branding/default.nix
    ./modules/boot/grub-theme.nix
    ./modules/boot/plymouth.nix
    ./modules/desktop/plasma.nix
    ./modules/hardware-support.nix
  ];

  isoImage = {
    isoName = lib.mkForce "bloom-nix.iso";
    volumeID = lib.mkForce "BLOOM_NIX";
    makeEfiBootable = true;
    makeUsbBootable = true;
    splashImage = lib.mkForce ../branding/splash.png;
    appendToMenuLabel = " Live";
    squashfsCompression = "gzip";
  };

  security.sudo.wheelNeedsPassword = false;

  environment.etc = {
    "skel/Desktop/install.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Install Bloom Nix
      Comment=Install the operating system to your computer
      Exec=calamares
      Icon=calamares
      Terminal=false
      Categories=System;
    '';
    "skel/Desktop/terminal.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Terminal
      Comment=Access the command line
      Exec=gnome-terminal
      Icon=utilities-terminal
      Terminal=false
      Categories=System;
    '';
  };

  boot = {
    loader.timeout = lib.mkForce 5;
    loader.grub.timeoutStyle = lib.mkForce "menu";
    plymouth.enable = true;
    supportedFilesystems = lib.mkForce [ "vfat" "ext4" "btrfs" "xfs" "ntfs" ];
  };

  system.stateVersion = "23.11";
}