{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix>
    ./modules/shared-config.nix
    ../modules/branding
    ../modules/desktop/gnome.nix
    ../modules/hardware-support.nix
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

  # Correct display manager configuration
  services.xserver = {
    enable = true;
    displayManager = {
      gdm = {
        enable = true;
        wayland = lib.mkDefault true;
      };
      autoLogin = {
        enable = true;
        user = "nixos";
      };
    };
    desktopManager.gnome.enable = true;
  };

  services.displayManager.defaultSession = "gnome";

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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  system.stateVersion = "23.11";
}