# config/build-iso.nix
# Configuration for building the Bloom Nix live ISO image with XFCE
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

    # Set splash screen
    splashImage = lib.mkForce ../branding/splash.png;

    # Add build information to the ISO label
    appendToMenuLabel = " Live";
    
    # Use gzip compression for better compatibility
    squashfsCompression = "gzip";
  };

  # Ensure XFCE is properly installed and configured
  services.xserver = {
    enable = true;
    
    # Force XFCE as the desktop environment
    desktopManager = {
      xfce.enable = lib.mkForce true;
      xterm.enable = false;
    };
    
    # Fix display manager conflict by using only one
    displayManager = {
      # Choose which display manager to use (pick ONE)
      lightdm = {
        enable = lib.mkForce true;  # We'll use LightDM for better compatibility
        background = ../branding/sddm-background.png;
      };
      sddm.enable = lib.mkForce false;  # Explicitly disable SDDM
      
      # Auto-login configuration
      autoLogin = {
        enable = true;
        user = "nixos";
      };
      defaultSession = "xfce";
    };
  };

  # Live environment user experience
  security.sudo.wheelNeedsPassword = false;

  # Create desktop shortcuts
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
      Exec=xfce4-terminal
      Icon=utilities-terminal
      Terminal=false
      Categories=System;
    '';
  };

  # Boot settings
  boot.loader.timeout = lib.mkForce 5;
  boot.loader.grub.timeoutStyle = lib.mkForce "menu";
  boot.plymouth.enable = true;  # Enable Plymouth for a nicer boot experience
  boot.supportedFilesystems = lib.mkForce [ "vfat" "ext4" "btrfs" "xfs" "ntfs" ];
  # boot.zfs.enabled = lib.mkForce false;  # Explicitly disable ZFS

  # Ensure better hardware support
  hardware.enableAllFirmware = true;

  # System state version
  system.stateVersion = "23.11";
}
