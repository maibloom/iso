# GNOME desktop environment configuration for Bloom Nix
{ config, lib, pkgs, inputs, outputs, ... }:

let
  # Default user for the live system and initial setup
  defaultUser = "nixos";
in {
  # Enable X server and Wayland
  services.xserver.enable = true;
  
  # Configure display manager - FIXED PATH STRUCTURE
  services.xserver.displayManager = {
    gdm = {
      enable = true;
      wayland = true;  # Enable Wayland support in GDM
    };
    # Auto-login for the live system
    autoLogin = {
      enable = lib.mkDefault true;
      user = lib.mkDefault defaultUser;
    };
  };

  # Enable GNOME desktop environment
  services.xserver.desktopManager.gnome.enable = true;
  
  # Core GNOME packages and applications
  environment.systemPackages = with pkgs; [
    # Core GNOME packages
    gnome-shell
    gnome-session
    gnome-settings-daemon
    gnome-control-center
    
    # Essential GNOME applications
    nautilus        # File manager
    gnome-terminal  # Terminal
    evince          # Document viewer
    gedit           # Text editor
    file-roller     # Archive manager
    gnome-screenshot # Screenshot tool
    eog             # Image viewer
    
    # GNOME extension management
    pkgs.gnome-tweaks
    gnome-extension-manager
    
    # Custom theme dependencies
    gtk3
    gtk4
    pkgs.adwaita-icon-theme
    sassc                 # For CSS compilation
    
    # Essential GNOME extensions
    gnomeExtensions.user-themes
    gnomeExtensions.dash-to-panel
    gnomeExtensions.just-perfection
    gnomeExtensions.blur-my-shell
    
    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];

  # Enable important GNOME-related services
  services.upower.enable = true;
  services.gnome.core-utilities.enable = true;
  
  # System-wide GTK integration
  programs.dconf.enable = true;
  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };

  # Set default applications for common file types
  xdg.mime.defaultApplications = {
    "application/pdf" = "org.gnome.Evince.desktop";
    "image/jpeg" = "org.gnome.eog.desktop";
    "image/png" = "org.gnome.eog.desktop";
    "text/plain" = "org.gnome.gedit.desktop";
    "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
    "application/zip" = "org.gnome.FileRoller.desktop";
  };
  
  # Set up system-wide wallpaper paths
  environment.pathsToLink = [ "/share/backgrounds" ];
}
