# KDE Plasma desktop environment configuration for Bloom Nix - Flake compatible
{ config, lib, pkgs, inputs, outputs, ... }:

{
  # Enable X server (still required for KDE Plasma)
  services.xserver.enable = true;

  # Configure display manager - using updated option paths
  services.displayManager = {
    sddm = {
      enable = true;
      theme = "breeze";
    };
    defaultSession = "plasma"; # using X11
  };

  # Enable KDE Plasma
  services.xserver.desktopManager.plasma5.enable = true; 
  # Note: Switch to plasma6.enable for newer NixOS versions in the future

  # Core KDE Plasma packages and applications
  environment.systemPackages = with pkgs; [
    # Core Plasma packages
    plasma5Packages.kwin
    plasma5Packages.plasma-workspace
    plasma5Packages.plasma-framework
    plasma5Packages.kwayland
    
    # For Wayland sessions
    plasma5Packages.kwayland-integration
    plasma5Packages.xdg-desktop-portal-kde

    # Core functionality
    libsForQt5.plasma-pa     # Volume control
    libsForQt5.plasma-nm     # Network management
    libsForQt5.powerdevil    # Power management
    libsForQt5.plasma-desktop  # Plasma desktop shell
    
    # Plasma integration components
    plasma5Packages.breeze-gtk
    plasma5Packages.breeze-icons
    plasma5Packages.kde-gtk-config
    
    # Essential applications - using correct package paths
    libsForQt5.konsole      # Terminal (Qt5 version)
    libsForQt5.dolphin      # File manager
    libsForQt5.okular       # Document viewer
    libsForQt5.kate         # Text editor
    libsForQt5.ark          # Archive manager
    libsForQt5.spectacle    # Screenshot tool
    libsForQt5.gwenview     # Image viewer
    
    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];

  # Enable important KDE-related services
  services.upower.enable = true;
  
  # System-wide Qt and GTK integration for consistent look and feel
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
 
  # Ensure GTK apps use Qt file dialogs and theme properly
  programs.dconf.enable = true;
  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };

  # Set default applications for common file types
  xdg.mime.defaultApplications = {
    "application/pdf" = "okular.desktop";
    "image/jpeg" = "org.kde.gwenview.desktop";
    "image/png" = "org.kde.gwenview.desktop";
    "text/plain" = "org.kde.kate.desktop";
    "application/x-compressed-tar" = "org.kde.ark.desktop";
    "application/zip" = "org.kde.ark.desktop";
    "video/mp4" = "org.kde.elisa.desktop";
    "audio/mpeg" = "org.kde.elisa.desktop";
  };
 
  # Set up system-wide wallpaper paths (used by Plasma)
  environment.pathsToLink = [ "/share/wallpapers" ];
}
