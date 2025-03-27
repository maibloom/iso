{ config, lib, pkgs, ... }:

{
  # Allow unfree packages but only when explicitly enabled
  nixpkgs.config.allowUnfree = true;

  # Basic networking support
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Core system packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    coreutils
    curl
    wget
    git
    vim
    htop
    pciutils
    usbutils
    file
    unzip
    
    # Terminal utilities
    tmux
    tree
    ripgrep
    fd
  ];

  # Standard time settings
  time.timeZone = lib.mkDefault "UTC";

  # Default locale settings
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Minimal user setup
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "bloom";
  };

  # Allow passwordless sudo in the live environment
  security.sudo.wheelNeedsPassword = false;

  # Enable essential services
  services = {
    # SSH for remote access (disabled by default)
    openssh.enable = false;
    
    # Basic device management
    udisks2.enable = true;
    
    # Network time synchronization
    timesyncd.enable = true;
  };

  # System stability options
  nix = {
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
