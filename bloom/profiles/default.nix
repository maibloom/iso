# Default installation profile for Bloom Nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # Include base system configuration
    ../modules/base.nix
    
    # Include branding
    ../modules/branding
    
    # Include desktop environment
    ../modules/desktop
    
    # Include hardware support
    ../modules/hardware
  ];
  
  # Enable NetworkManager for all installations
  networking.networkmanager.enable = true;
  
  # Enable sound with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Include base packages for all installations
  environment.systemPackages = with pkgs; [
    # Basic utilities
    vim nano wget curl git htop
    zip unzip file tree rsync
    
    # Desktop applications
    firefox
    thunderbird
    libreoffice-qt
    vlc
    gimp
    
    # System utilities
    gnome.gnome-disk-utility
    gparted
    keepassxc
    
    # Archive support
    p7zip
    unrar
    
    # Network tools
    networkmanager
    networkmanagerapplet
    
    # Printing support
    cups
    system-config-printer
    
    # Bluetooth management
    bluez
    blueman
  ];
  
  # Enable automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    channel = "https://nixos.org/channels/nixos-23.11";
  };
  
  # Configure GRUB bootloader
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
    configurationLimit = 10;
  };
  
  # Configure automatic login for default user
  services.xserver.displayManager = {
    autoLogin = {
      enable = true;
      user = "bloom";
    };
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Configure firewall
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 80 443 ]; # HTTP/HTTPS
  };
  
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  
  # Enable automatic optimization
  nix.settings.auto-optimise-store = true;
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # System state version
  system.stateVersion = "23.11";
}
