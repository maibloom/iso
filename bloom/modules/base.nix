{ config, lib, pkgs, ... }:

{
  # Allow unfree packages but only when explicitly enabled
  nixpkgs.config.allowUnfree = true;

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
}
