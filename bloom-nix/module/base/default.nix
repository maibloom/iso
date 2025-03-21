# Common base configuration for Bloom Nix
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

  # System state version - update when making significant changes
  system.stateVersion = "23.11";

  # Networking configuration
  networking = {
    networkmanager.enable = true;
  };
 
  # Time zone - this can be changed during installation
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

  # Boot loader configuration (shared across systems)
  boot.loader.grub.useOSProber = true;

  # Enable fwupd for firmware updates
  services.fwupd.enable = true;
}
