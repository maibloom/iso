{ config, pkgs, ... }:

{
  services.xserver.enable = true;

  # Configure Plasma desktop environment
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure SDDM as the display manager (login screen)
  services.xserver.displayManager.sddm.enable = true;

  # Add Plasma and KDE applications to the live environment
  environment.systemPackages = with pkgs; [
    plasma-desktop         # Core Plasma packages
    kdeApplications.dolphin   # File manager
    kdeApplications.konsole   # Terminal emulator
    kdeApplications.kate      # Text editor
    kdeApplications.spectacle # Screenshot tool
  ];
}
