# modules/desktop/plasma.nix

{ config, lib, pkgs, ... }:

let
  # Define the path to your branding directory - adjust this if needed
  brandingDir = ../../../branding;
in {
  # Enable X server (still required for KDE Plasma)
  services.xserver.enable = true;

  # Configure display manager - using updated option paths
  services.displayManager = {
    sddm = {
      enable = true;
      theme = "breeze";
      
      # Use the Bloom login background for SDDM
      settings = {
        Theme = {
          Background = "${brandingDir}/sddm-background.png";
        };
      };
    };
    defaultSession = "plasma"; # using X11
  };

  # Enable KDE Plasma
  services.xserver.desktopManager.plasma5.enable = true; # Use plasma6.enable for newer NixOS versions

  # Core KDE Plasma packages and applications
  environment.systemPackages = with pkgs; [
    # Core Plasma packages
    plasma5Packages.kwin
    plasma5Packages.plasma-workspace
    plasma5Packages.plasma-framework
    plasma5Packages.kwayland
    # For Wayland sessions specifically
    plasma5Packages.kwayland-integration
    plasma5Packages.xdg-desktop-portal-kde

    # Core functionality
    libsForQt5.plasma-pa       # Volume control
    libsForQt5.plasma-nm       # Network management
    libsForQt5.powerdevil      # Power management
    libsForQt5.plasma-desktop  # Plasma desktop shell
    libsForQt5.plasma-workspace
    
    # Essential applications
    konsole       # Terminal
    dolphin       # File manager
    okular        # Document viewer
    kate          # Text editor
    ark           # Archive manager
    spectacle     # Screenshot tool
    gwenview      # Image viewer
    
    # Multimedia support
    ffmpeg
    libdvdcss
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    
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
  services.pipewire = {
    enable = true;
    pulse.enable = true;  # Replacement for PulseAudio
    alsa.enable = true;   # ALSA support
    jack.enable = true;   # JACK support
  };

  # Bluetooth support for KDE Plasma
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
  # This makes all wallpapers in the branding directory available system-wide
  environment.pathsToLink = [ "/share/wallpapers" ];
  
  # Create a system-wide symbolic link for the default Bloom background
  # Using proper path reference via brandingDir
  system.activationScripts.bloombg = ''
    mkdir -p /usr/share/backgrounds/bloom
    ln -sf ${brandingDir}/backgrounds/background1.png /usr/share/backgrounds/bloom/default.png
  '';

  # Notes for users:
  # 1. This file handles system-wide configuration only
  # 2. User-specific customization is handled by plasma-home.nix/plasma-theme.nix
  # 3. Apply user-specific settings via home-manager
}
