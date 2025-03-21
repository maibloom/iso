# config/modules/shared-config.nix
# Shared configuration between ISO and installed system
{ config, pkgs, lib, ... }:

{
  # System identity
  system.nixos.distroName = "Bloom Nix";
  
  # Package management settings
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
  };
  
  # Nix package manager optimizations
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  
  # Core packages used by both live system and installation
  environment.systemPackages = with pkgs; [
    # CLI essentials
    vim nano wget curl git
    htop lsof pciutils pkgs.usbutils
    zip unzip file tree rsync
    
    # Desktop environment support
    libsForQt5.packagekit-qt
    libsForQt5.qt5.qtgraphicaleffects
    kdePackages.dolphin
    
    # Browser
    brave
    
    # Filesystem tools
    ntfs3g fuse exfat

    # liberoffice
    libreoffice
    
    # video tool
    vlc
    
    # Development
    libgcc rustup

    # Plasma packages
    plasma5Packages.breeze-gtk
    plasma5Packages.breeze-icons
    plasma5Packages.kde-gtk-config
  ];
  
  # Locale and internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
      "de_DE.UTF-8/UTF-8"
      "fr_FR.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
    ];
  };
  
  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Audio with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Basic networking configuration
  networking = {
    networkmanager.enable = true;
  };
  
  # Time zone
  time.timeZone = "UTC";
  
  # System state version
  system.stateVersion = "23.11";
}
