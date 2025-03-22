# Basic configuration module for Bloom Nix
{ config, pkgs, lib, inputs, ... }:

{
  # System identity
  system.nixos.distroName = "Bloom Nix";
  networking.hostName = "bloomnix";
  
  # Configure user accounts
  users.users.bloomnix = {
    isNormalUser = true;
    description = "Bloom Nix User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    # No password required for login
    initialPassword = "";
    hashedPassword = "";
  };
  
  # Allow sudo without password
  security.sudo.wheelNeedsPassword = false;
  
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
      trusted-public-keys = lib.mkDefault [];
      substituters = lib.mkDefault [];
    };
    
    # Registry entries for this flake
    registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;
    
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
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH
      allowedUDPPorts = [];
    };
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
    
    # System utilities
    lshw
    pciutils
    usbutils
    dmidecode
    
    # Network utilities
    inetutils
    traceroute
    nmap
    
    # Power management
    powertop
    tlp
  ];
  
  # Font configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
    
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        monospace = [ "Fira Code" "Liberation Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
  
  # System services
  services = {
    # SSH for remote management
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };
    
    # Time synchronization
    timesyncd.enable = true;
    
    # Automatic updates
    fwupd.enable = true;
  };
  
  # Improve system security
  security = {
    polkit.enable = true;
    pam.loginLimits = [{
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "4096";
    }];
  };
}
