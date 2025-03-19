# Configuration for building the Bloom Nix live ISO image
{ config, pkgs, lib, ... }:

{
  imports = [
    # Base ISO configuration from nixpkgs
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix>

    # Import shared configuration
    ./modules/shared-config.nix

    # Import branding and desktop environment
    ../modules/branding
    ../modules/desktop/plasma.nix

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

  # Force SDDM as the display manager - critical to resolve the conflict
  services.displayManager.execCmd = lib.mkForce "exec /run/current-system/sw/bin/sddm";

  # Configure autologin
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };
  services.displayManager.defaultSession = "plasma";

  # Enable KDE Plasma
  services.desktopManager.plasma6.enable = true;
  services.xserver.enable = true;

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
      Exec=konsole
      Icon=utilities-terminal
      Terminal=false
      Categories=System;
    '';
  };

  # Boot settings
  boot.loader.timeout = lib.mkForce 5;
  boot.loader.grub.timeoutStyle = lib.mkForce "menu";
  boot.plymouth.enable = true;
  boot.supportedFilesystems = lib.mkForce [ "vfat" "ext4" "btrfs" "xfs" "ntfs" ];
 
  # Ensure better hardware support
  hardware.enableAllFirmware = true;

  # System state version
  system.stateVersion = "23.11";
}
