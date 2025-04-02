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
    initialPassword = "nixos"; # Set a default password for testing
  };

  # Enable NetworkManager for networking support in live environment
  networking.networkmanager.enable = true;

  # Enable basic firewall settings
  networking.firewall.enable = true;
}
