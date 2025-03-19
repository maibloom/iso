# modules/desktop/plasma.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./plasma-theme.nix
  ];
  
  # Enable KDE Plasma 6 desktop environment
  services.xserver = {
    enable = true;
    
    # Configure display manager
    displayManager = {
      sddm.enable = true;
      defaultSession = "plasma";
    };
    
    # Enable Plasma 6
    desktopManager.plasma6 = {
      enable = true;
    };
  };

  # Core KDE packages and applications - optimized for Plasma 6
  environment.systemPackages = with pkgs; [
    # Core KDE packages
    kdePackages.plasma-desktop
    kdePackages.plasma-workspace
    kdePackages.kwin
    kdePackages.systemsettings
    
    # Essential KDE applications
    kdePackages.dolphin           # File manager
    kdePackages.konsole           # Terminal
    kdePackages.kate              # Text editor
    kdePackages.ark               # Archive manager
    kdePackages.spectacle         # Screenshot tool
    kdePackages.okular            # Document viewer
    kdePackages.elisa             # Music player
    kdePackages.discover          # Software center
    
    # Desktop functionality
    kdePackages.plasma-nm         # Network manager
    kdePackages.plasma-pa         # Audio volume
    kdePackages.plasma-workspace-wallpapers
    kdePackages.plasma-browser-integration
    kdePackages.kwallet-pam       # Wallet/Keyring
    kdePackages.kio               # KDE IO slaves
    kdePackages.print-manager     # Printer management
    
    # Useful utilities
    kdePackages.filelight         # Disk usage viewer
    kdePackages.kcalc             # Calculator
    kdePackages.kinfocenter       # System information
    kdePackages.ksystemstats      # System monitor
    kdePackages.kgpg              # GnuPG frontend
    kdePackages.kdeconnect-kde    # Phone integration
    
    # Media and appearance
    kdePackages.gwenview          # Image viewer
    kdePackages.breeze-icons      # Icon theme
    kdePackages.breeze-gtk        # GTK theme matching
    kdePackages.plasma-integration # Better desktop integration
    
    # Themes and visual improvements
    kdePackages.breeze            # Default theme
    kdePackages.oxygen-sounds     # System sounds
    
    # Additional KDE functionality
    kdePackages.plasma-systemmonitor  # Detailed system monitoring
    kdePackages.kscreen              # Display configuration
    kdePackages.plasma-disks         # Disk health monitoring
    kdePackages.kaccounts-integration # Online account integration
    kdePackages.kaccounts-providers  # Account providers
    
    # Multimedia support
    ffmpeg                        # Multimedia backend
    libdvdcss                     # DVD support
    gst_all_1.gstreamer           # Media framework
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav           # Media codecs
  ];

  # Enable important KDE-specific services
  services.accounts-daemon.enable = true;
  services.upower.enable = true;
  
  # Bluetooth support for KDE with improved user experience
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;  # More convenient for users
    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = true;
        # Enable Bluetooth audio by default
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  
  # QT and GTK integration for a consistent look
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
  
  programs.dconf.enable = true;  # Needed for proper GTK integration
  
  # Set default applications for common file types
  xdg.mime.defaultApplications = {
    "application/pdf" = "okularApplication_pdf.desktop";
    "image/jpeg" = "org.kde.gwenview.desktop";
    "image/png" = "org.kde.gwenview.desktop";
    "text/plain" = "org.kde.kate.desktop";
    "application/x-compressed-tar" = "org.kde.ark.desktop";
    "application/zip" = "org.kde.ark.desktop";
    "video/mp4" = "org.kde.haruna.desktop";
    "audio/mpeg" = "org.kde.elisa.desktop";
  };
  
  # Additional branding assets configuration
  environment.etc = {
    # Make sure no entries overlap with plasma-theme.nix
    "bloom-nix/backgrounds/default.png".source = ../../branding/background.png;
    "bloom-nix/backgrounds/login.png".source = ../../branding/sddm-background.png;
  };
  
  # Configure SDDM for optimal Plasma experience
  services.xserver.displayManager.sddm = {
    settings = {
      Theme = {
        # Set theme and background
        Current = "breeze";
        CursorTheme = "breeze_cursors";
        Font = "Noto Sans,10,-1,5,50,0,0,0,0,0";
        # Use custom background
        Background = "../../branding/background.png";
      };
      # Better user experience settings
      Autologin = {
        Relogin = false;
        Session = "plasma";
      };
      X11 = {
        # Better display scaling support
        EnableHiDPI = true;
        ServerArguments = "-dpi 96 -nolisten tcp";
      };
    };
  };
}
