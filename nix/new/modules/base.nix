{ config, pkgs, ... }:

{
  # Base system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    wget
    curl
    brave
  ];

  # User configuration for live session
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "bloom"; # Set a default password for testing
  };

  # Enable basic firewall settings
  networking.firewall.enable = true;
}
