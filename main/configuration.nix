# configuration.nix
# Basic NixOS configuration for Bloom Nix ISO

{ config, pkgs, lib, ... }:

{
  imports = [
    # Include the minimal installation CD NixOS module
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Basic system identification
  networking.hostName = "bloom-nix";
  system.stateVersion = "23.05";
  
  # Create a default user with sudo access
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "bloom";
  };
  
  # Allow automatic login on the live system
  services.getty.autologinUser = "bloom";
  
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
    makeEfiBootable = true;
    
    # Make the ISO bootable on legacy BIOS systems
    makeUsbBootable = true;
    
    # Custom volume ID and name
    volumeID = "BLOOM_NIX";
    isoName = "bloom-nix.iso";
    
    # Add a custom label to the boot menu
    appendToMenuLabel = " Bloom Nix";
    
    # Use gzip compression for better compatibility
    squashfsCompression = "gzip -Xcompression-level 1";
  };
  
  # Boot configuration
  boot = {
    # Use a stable kernel for better compatibility
    kernelPackages = pkgs.linuxPackages_5_15;
    
    # Set kernel parameters for better compatibility and debugging
    kernelParams = [ 
      "nomodeset"
      "boot.shell_on_fail"
    ];
    
    # Increase console logging for debugging
    consoleLogLevel = 7;
    initrd.verbose = true;
  };
  
  # Reduce size by disabling documentation
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
  };
}
