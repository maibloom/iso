# KDE Plasma 6 packages and configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Essential packages for a functional desktop
  environment.systemPackages = with pkgs; [
    # Core KDE Packages
    kdePackages.plasma-workspace
    kdePackages.kwayland
    kdePackages.kwin

    # Basic Plasma integration
    kdePackages.plasma-pa         # Volume control
    kdePackages.plasma-nm         # Network management
    kdePackages.powerdevil        # Power management
    kdePackages.plasma-desktop    # Plasma desktop shell

    # Essential applications
    kdePackages.konsole           # Terminal
    kdePackages.dolphin           # File manager
    kdePackages.kate              # Text editor
    kdePackages.ark               # Archive manager

    # Web browser
    firefox

    # Fonts
    noto-fonts
    noto-fonts-emoji

    # VM support
    spice-vdagent
  ];

  # Enable important services
  services.upower.enable = true;

  # Basic networking
  networking.networkmanager.enable = true;
}
