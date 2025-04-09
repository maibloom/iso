{ config, lib, pkgs, ... }:

let
  # Define the path to your branding directory
  brandingDir = ../branding;
in {
  # This file contains basic theme configuration for KDE Plasma
  # It's designed to be imported by the user's home-manager configuration
  
  # Basic KDE Plasma appearance settings
  programs.plasma = {
    # Basic settings for workspace appearance
    workspace = {
      # Set the global theme (look and feel package)
      lookAndFeel = "org.kde.breezedark.desktop";
      
      # Configure cursor theme and size
      cursor = {
        theme = "Breeze_Snow";
        size = 24;
      };
      
      # Set the icon theme
      iconTheme = "Papirus-Dark";
      
      # Configure widget style and color scheme
      theme = {
        name = "Breeze";
        colorScheme = "BreezeDark";
      };
      
      # Configure the default Bloom wallpaper
      # This uses the system-wide symbolically linked default wallpaper
      wallpaper = "/usr/share/backgrounds/bloom/default.png";
    };
    
    # Configure font settings
    fonts = {
      general = {
        family = "Noto Sans";
        pointSize = 10;
      };
      fixed = {
        family = "Fira Code";
        pointSize = 10;
      };
      smallFixed = {
        family = "Fira Code";
        pointSize = 8;
      };
      toolTip = {
        family = "Noto Sans";
        pointSize = 9;
      };
    };
    
    # Configure KWin theme and effects
    kwin = {
      # Basic KWin settings
      theme = "Breeze";
      
      # Effects configuration
      effects = {
        blurredBackground.enable = true;
        wobblyWindows.enable = false;
        magicLamp.enable = true;
      };
    };
  };
  
  # Additional theme-related packages to install
  home.packages = with pkgs; [
    papirus-icon-theme
    libsForQt5.breeze-gtk
    libsForQt5.breeze-icons
    libsForQt5.plasma-browser-integration
    
    # Add wallpaper packages here if needed
  ];
  
  # Add branding wallpapers to the user's wallpaper collection
  # This makes all wallpapers in the branding directory available to the user
  home.file.".local/share/wallpapers/bloom-backgrounds".source = "${brandingDir}/backgrounds";
  
  # Low-level configuration for appearance settings
  programs.plasma.configFile = {
    # Disable animations for better performance if needed
    kdeglobals.KDE.AnimationDurationFactor = 0.7;  # Slightly faster animations
    
    # Configure window decoration buttons
    kwinrc."org.kde.kdecoration2" = {
      ButtonsOnLeft = "XAI";   # Close (X), All Desktops (A), Min (I)
      ButtonsOnRight = "MFS";  # Maximize (M), Fullscreen (F), Menu (S)
      theme = "Breeze";        # Window decoration theme
    };
    
    # Configure file dialogs
    kdeglobals.KFileDialog = {
      ShowBookmarks = true;
      ShowHidden = false;
      ShowPreview = true;
      "Show Full Path" = false;
    };
    
    # Configure splash screen to use Bloom branding
    ksplashrc.KSplash = {
      Engine = "KSplashQML";
      Theme = "org.kde.breeze.desktop";
    };
  };
}
