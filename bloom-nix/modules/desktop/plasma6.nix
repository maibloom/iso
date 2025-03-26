# plasma6.nix

{ config, lib, pkgs, ... }:

let
  # Helper function to safely try different package namespaces
  tryPackage = name:
    if pkgs ? kdePackages && pkgs.kdePackages ? ${name} then pkgs.kdePackages.${name}
    else if pkgs ? plasma5Packages && pkgs.plasma5Packages ? ${name} then pkgs.plasma5Packages.${name}
    else if pkgs ? ${name} then pkgs.${name}
    else null;

  # List of KDE/Plasma packages
  plasmaPackages = [
    (tryPackage "plasma-workspace")
    (tryPackage "kwayland")
    (tryPackage "kwin")
    (tryPackage "plasma-pa")
    (tryPackage "plasma-nm")
    (tryPackage "powerdevil")
    (tryPackage "plasma-desktop")
    (tryPackage "konsole")
    (tryPackage "dolphin")
    (tryPackage "kate")
    (tryPackage "ark")
  ];

  # Filter out any null values
  availablePlasmaPackages = builtins.filter (pkg: pkg != null) plasmaPackages;

in {
  # Essential packages for a functional desktop
  environment.systemPackages = with pkgs;
    availablePlasmaPackages ++ [
      firefox
      noto-fonts
      noto-fonts-emoji
      spice-vdagent
      xterm
      pcmanfm
      leafpad
    ];

  # Enable the X server
  services.xserver.enable = true;

  # Configure SDDM display manager with Wayland support
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Enable KDE Plasma 6 desktop environment
  services.desktopManager.plasma6.enable = true;

  # Set the default session to Plasma (Wayland)
  services.displayManager.defaultSession = "plasmawayland";

  # VM-friendly video drivers
  services.xserver.videoDrivers = [ "qxl" "vmware" "modesetting" "fbdev" ];

  # Enable important services
  services.upower.enable = true;
}
