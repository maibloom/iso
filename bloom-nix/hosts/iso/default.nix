# Minimal Plasma 6 desktop environment configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
  };


  # Essential packages for a functional desktop
  environment.systemPackages = with pkgs; [
    # Core KDE Packages
    kdePackages.plasma-workspace
    kdePackages.kwayland
    kdePackages.kwin

    # Basic Plasma integration
    kdePackages.plasma-pa        # Volume control
    kdePackages.plasma-nm        # Network management
    kdePackages.powerdevil       # Power management
    kdePackages.plasma-desktop   # Plasma desktop shell

    # Essential applications
    kdePackages.konsole          # Terminal
    kdePackages.dolphin          # File manager
    kdePackages.kate             # Text editor
    kdePackages.ark              # Archive manager

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

  # System-wide Qt integration
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  # VM-friendly settings
  services.xserver.videoDrivers = [ "qxl" "vmware" "modesetting" "fbdev" ];
  boot.kernelParams = [ "nomodeset" "ibt=off" ];

  # Basic networking
  networking.networkmanager.enable = true;
}
