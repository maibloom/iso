# Base configuration for Bloom Nix - Core system settings
{ config, lib, pkgs, ... }:

{
  # Set the NixOS release version
  system.stateVersion = "23.11";
  
  # System identity
  networking.hostName = "bloom-nix";
  
  # User account configuration
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "bloom";  # Default password, should be changed on first login
    description = "Bloom Nix User";
  };
  
  # Auto-login for the live system
  services.getty.autologinUser = "bloom";
  
  # Basic command-line tools
  environment.systemPackages = with pkgs; [
    # Text editors
    vim nano
    
    # Network tools
    wget curl
    
    # System utilities
    git htop
    zip unzip
    file tree
    rsync
    
    # Process management
    killall
    lsof
  ];
  
  # Core system services
  services = {
    # SSH for remote access (disabled by default in the final installation)
    openssh.enable = true;
  };
  
  # NetworkManager must be under networking, not services
  networking = {
    # Network Manager for ease of network configuration
    networkmanager.enable = true;
    
    # Disable wpa_supplicant to prevent conflicts with NetworkManager
    wireless.enable = false;
  };
  
  # Boot configuration
  boot = {
    # Use a stable kernel version
    kernelPackages = pkgs.linuxPackages;
    
    # Add boot parameters for better compatibility
    kernelParams = [ "nomodeset" "boot.shell_on_fail" ];
    
    # Plymouth for a graphical boot experience
    plymouth.enable = true;
  };
  
  # Nix package manager configuration
  nix = {
    # Automatic optimization to save disk space
    settings.auto-optimise-store = true;
    
    # Garbage collection to keep the system clean
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    
    # Enable nix command and flakes for users who want them
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  
  # Security settings
  security = {
    # Allow sudo without password for the live environment
    sudo.wheelNeedsPassword = false;
    
    # Polkit rules for the live environment
    polkit.extraConfig = ''
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
  };
  
  # Localization settings
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Console settings
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
