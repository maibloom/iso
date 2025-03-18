# config/configuration.nix
# Main configuration for installed Bloom Nix system
{ config, pkgs, lib, ... }:

{
  imports = [
    # Include hardware configuration
    ./hardware-configuration.nix
    
    # Include shared configuration
    ./modules/shared-config.nix
    
    # Include desktop environment
    ../modules/desktop/xfce.nix
    
    # Include branding
    ../modules/branding
    
    # Include installer (will be removed after installation)
    ../modules/installer/calamares.nix
  ];

  # Boot loader configuration - CONDITIONAL to avoid ISO conflicts
  # This is the key change to prevent conflicts when building the ISO
  boot.loader = lib.mkIf (!config.system.build ? isoImage) {
    timeout = 5;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      theme = ../branding/grub/theme;
      backgroundColor = "#454d6e";
    };
    efi.canTouchEfiVariables = true;
  };

  # Hostname for installed system
  networking.hostName = "bloom-nix";
  
  # Installed-system specific packages
  environment.systemPackages = with pkgs; [
    # System administration tools for installed system only
    gparted
    firefox
    thunderbird
    libreoffice
    neofetch
    vlc
    gimp
    
    # Additional system utilities
    gnome.gnome-disk-utility
    gnome.gnome-system-monitor
    xfce.thunar-archive-plugin
    xfce.thunar-volman
  ];

  # User account setup for installed system
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "scanner" "lp" ];
    initialPassword = "bloom";
  };
  
  # Security settings for installed system
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true; # Password required on installed system
  };
  
  # Enable OpenSSH only in installed system
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };
  
  # Enable automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
    flake = "github:your-username/bloom-nix-project";
  };
  
  # Install recommended documentation
  documentation = {
    enable = true;
    dev.enable = true;
    doc.enable = true;
    info.enable = true;
    man.enable = true;
    nixos.enable = true;
  };
  
  # Default applications
  xdg.mime.defaultApplications = {
    "text/plain" = "org.xfce.mousepad.desktop";
    "application/pdf" = "org.gnome.Evince.desktop";
    "image/jpeg" = "org.gnome.eog.desktop";
    "image/png" = "org.gnome.eog.desktop";
    "video/mp4" = "vlc.desktop";
    "audio/mp3" = "vlc.desktop";
  };
}
