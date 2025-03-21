{ config, lib, pkgs, ... }:

{
  # Enable GNOME desktop environment
  services.xserver = {
    enable = true;

    # Configure display manager
    displayManager = {
      gdm.enable = true;
      defaultSession = "gnome";
    };

    # Enable GNOME
    desktopManager.gnome.enable = true;
  };

  # Core GNOME packages and applications
  environment.systemPackages = with pkgs; [
    # Core GNOME packages
    gnome3.gnome-shell
    gnome3.gnome-shell-extensions
    gnome3.gnome-control-center
    gnome3.nautilus
    gnome3.gnome-terminal
    gnome3.evince    # Document viewer
    gnome3.gedit     # Text editor
    gnome3.gnome-calculator   # Calculator
    gnome3.gnome-system-monitor  # System monitor

    # Essential GNOME applications
    gnome3.nautilus    # File manager
    gnome3.gnome-maps  # Maps
    gnome3.gnome-photos    # Photo viewer
    gnome3.gnome-music    # Music player
    gnome3.gnome-software   # Software center
    gnome3.gnome-screenshot  # Screenshot tool

    # Multimedia support
    ffmpeg
    libdvdcss
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  # Enable important GNOME-specific services
  services.accounts-daemon.enable = true;
  services.upower.enable = true;

  # Bluetooth support for GNOME
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # GTK integration for consistent look and feel with GNOME
  qt = {
    enable = lib.mkForce false;  # GNOME doesn't need QT integration, unlike Plasma
  };

  # Set default applications for common file types
  xdg.mime.defaultApplications = {
    "application/pdf" = "evince.desktop";
    "image/jpeg" = "gnome-photos.desktop";
    "image/png" = "gnome-photos.desktop";
    "text/plain" = "gedit.desktop";
    "application/x-compressed-tar" = "org.gnome.Archive.desktop";
    "application/zip" = "org.gnome.Archive.desktop";
    "video/mp4" = "gnome-music.desktop";
    "audio/mpeg" = "gnome-music.desktop";
  };

  imports = [
    # Import GNOME theme configuration
    ./gnome-theme.nix
  ];
}
