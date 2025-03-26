# Adaptive KDE Plasma configuration for Bloom Nix
{ config, lib, pkgs, ... }:

let
  # Helper function to safely try different package namespaces
  # This will try each namespace in order and return the first package that exists
  tryPackage = name:
    if pkgs ? kdePackages && pkgs.kdePackages ? ${name} then pkgs.kdePackages.${name}
    else if pkgs ? plasma5Packages && pkgs.plasma5Packages ? ${name} then pkgs.plasma5Packages.${name}
    else if pkgs ? ${name} then pkgs.${name}
    else null;

  # Create a list of KDE/Plasma packages we want, using our safe function
  plasmaPackages = [
    # Core KDE Packages
    (tryPackage "plasma-workspace")
    (tryPackage "kwayland")
    (tryPackage "kwin")

    # Basic Plasma integration
    (tryPackage "plasma-pa")       # Volume control
    (tryPackage "plasma-nm")       # Network management
    (tryPackage "powerdevil")      # Power management
    (tryPackage "plasma-desktop")  # Plasma desktop shell

    # Essential applications
    (tryPackage "konsole")         # Terminal
    (tryPackage "dolphin")         # File manager
    (tryPackage "kate")            # Text editor
    (tryPackage "ark")             # Archive manager
  ];

  # Filter out any null values (packages that weren't found)
  availablePlasmaPackages = builtins.filter (pkg: pkg != null) plasmaPackages;

in {
  # Essential packages for a functional desktop
  environment.systemPackages = with pkgs;
    # Add all available Plasma packages
    availablePlasmaPackages
    # Add always-available packages
    ++ [
      # Web browser
      firefox

      # Fonts
      noto-fonts
      noto-fonts-emoji

      # VM support
      spice-vdagent

      # Fallback generic applications (in case KDE ones aren't available)
      xterm
      pcmanfm
      leafpad
    ];

  # Enable important services
  services.upower.enable = true;

  # Basic networking
  networking.networkmanager.enable = true;
}
