# Base module for Bloom Nix - Flake compatible
{ config, pkgs, lib, inputs, ... }:

{
  # System identity
  system.nixos.distroName = "Bloom Nix";
 
  # Package management settings
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
  };

  # Nix package manager optimizations - flakes-specific
  nix = {
    settings = {
      auto-optimise-store = true;
      # Enable flakes and nix-command by default
      experimental-features = [ "nix-command" "flakes" ];
      # Trust the flake registry by default
      trusted-public-keys = lib.mkDefault [];
      substituters = lib.mkDefault [];
    };
    
    # Make nixpkgs available in the NIX_PATH
    nixPath = lib.mkForce [
      "nixpkgs=${inputs.nixpkgs}"
    ];
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # System state version
  system.stateVersion = "23.11";

  # Basic networking configuration
  networking = {
    networkmanager.enable = true;
  };
 
  # Time zone
  time.timeZone = "UTC";
 
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

  # Core system packages
  environment.systemPackages = with pkgs; [
    # CLI essentials
    vim
    nano
    wget
    curl
    git
    htop
    lsof
    zip
    unzip
    file
    tree
    rsync
  ];
}
