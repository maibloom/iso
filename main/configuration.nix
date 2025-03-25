# configuration.nix
# Basic NixOS configuration for Bloom Nix ISO

{ config, pkgs, lib, ... }:

{
  imports = [
    # Include the minimal installation CD NixOS module
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical.nix>
    ./hardware/default.nix
  ];

  # Basic system identification
  networking.hostName = lib.mkForce "bloom-nix";
  system.stateVersion = "23.05";
  
  # Create a default user with sudo access
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "bloom";
  };
  
  # Allow automatic login on the live system
  services.getty.autologinUser = lib.mkForce "bloom";
  
  # Install basic packages
  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    wget
    htop
  ];
  
  # Enable SSH for remote access
  services.openssh.enable = true;
  
  # Disable GUI
  services.xserver.enable = false;
  
  # ISO image customization
  isoImage = {
    # Make the ISO bootable on EFI systems
    makeEfiBootable = lib.mkForce true;
    
    # Make the ISO bootable on legacy BIOS systems
    makeUsbBootable = lib.mkForce true;
    
    # Custom volume ID and name
    volumeID = lib.mkForce "BLOOM_NIX";
    isoName = lib.mkForce "bloom-nix.iso";
    
    # Add a custom label to the boot menu
    appendToMenuLabel = lib.mkForce " Bloom Nix";
    
    # Use gzip compression for better compatibility
    squashfsCompression = lib.mkForce "gzip -Xcompression-level 1";
  };
  
  # Boot configuration
  boot = {
    # Use a stable kernel for better compatibility
    kernelPackages = lib.mkDefault pkgs.linuxPackages_5_15;
    
    # Set kernel parameters for better compatibility and debugging
    kernelParams = [ 
      "nomodeset"
      "boot.shell_on_fail"
    ];
    
    # Increase console logging for debugging
    consoleLogLevel = 7;
    initrd.verbose = true;
  };
  
  # Disable automatic installation of packages that might conflict
  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.info.enable = lib.mkForce false;
  documentation.doc.enable = lib.mkForce false;
  
  # Override any potentially conflicting settings from the installation media
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = lib.mkDefault true;
  
  # Disable any automatic hardware configuration that might conflict
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  
  # Override any services that might be enabled by default in the installation media
  systemd.services.display-manager.enable = lib.mkForce false;
  
  # Override anything else that might conflict
  security.polkit.enable = lib.mkDefault true;
}
