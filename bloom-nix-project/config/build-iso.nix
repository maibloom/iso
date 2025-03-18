# config/build-iso.nix
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
    ../modules/desktop/xfce.nix
    
    # Import hardware support
    ../modules/hardware-support.nix
  ];

  # IMPORTANT: We do NOT import configuration.nix here to avoid conflicts!

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
  };
 
  # Using absolute minimum settings to avoid errors
  
  # Minimal list of supported filesystems
  boot.supportedFilesystems = lib.mkForce [ "vfat" "ext4" ];
  
  # Minimal kernel modules
  boot.initrd.availableKernelModules = lib.mkForce [ "ahci" "sd_mod" "usb_storage" "xhci_pci" ];
  boot.kernelModules = lib.mkForce [ ];
  
  # Disable auto-detection and complex features
  boot.initrd.includeDefaultModules = lib.mkForce false;
  
  # ISO-specific boot settings
  boot.loader.timeout = lib.mkForce 5;
  boot.loader.grub.timeoutStyle = lib.mkForce "hidden";
  
  # We removed systemPackages as they're already defined in configuration.nix
  # This avoids duplicate package definitions
 
  # Live environment user experience
  security.sudo.wheelNeedsPassword = false;
 
  # Auto-login for live environment
  services.xserver.displayManager = {
    autoLogin = {
      enable = true;
      user = "nixos";
    };
    defaultSession = "xfce";
  };
 
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
 
  # System state version
  system.stateVersion = "23.11";
}
