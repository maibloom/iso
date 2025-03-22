# KDE Plasma 6 desktop environment configuration for Bloom Nix
{ config, lib, pkgs, inputs, outputs, ... }:

let
  # Default user for the live system and initial setup
  defaultUser = "nixos";
in {
  # Enable X server and Wayland
  services.xserver.enable = true;
  
  # Configure display manager
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;  # Enable Wayland support in SDDM
      theme = "breeze";
    };
    # Default to Plasma on Wayland for modern experience
    defaultSession = "plasma"; 
    # Auto-login for the live system
    autoLogin = {
      enable = lib.mkDefault true;
      user = lib.mkDefault defaultUser;
    };
  };

  # Enable KDE Plasma 6
  services.xserver.desktopManager.plasma6.enable = true;

  # Core KDE Plasma 6 packages and applications
  environment.systemPackages = with pkgs; [
    # Core KDE Packages
    kdePackages.plasma-workspace
    kdePackages.plasma-framework
    kdePackages.kwayland
    kdePackages.kwin
    
    # Plasma integration components
    kdePackages.breeze-gtk
    kdePackages.breeze-icons
    kdePackages.kde-gtk-config
    kdePackages.xdg-desktop-portal-kde
    
    # Core functionality
    kdePackages.plasma-pa      # Volume control
    kdePackages.plasma-nm      # Network management
    kdePackages.powerdevil     # Power management
    kdePackages.plasma-desktop # Plasma desktop shell
    
    # Essential applications
    kdePackages.konsole        # Terminal
    kdePackages.dolphin        # File manager
    kdePackages.okular         # Document viewer
    kdePackages.kate           # Text editor
    kdePackages.ark            # Archive manager
    kdePackages.spectacle      # Screenshot tool
    kdePackages.gwenview       # Image viewer
    kdePackages.elisa          # Music player
    
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

  # Define the home-manager configuration for Plasma customization
  home-manager.users.${defaultUser} = { pkgs, ... }: {
    imports = [
      # Import plasma-manager module
      inputs.plasma-manager.homeManagerModules.plasma-manager
    ];
    
    # Define Plasma customization with plasma-manager
    programs.plasma = {
      enable = true;
      
      # Global theme settings - very minimal to start with
      workspace = {
        lookAndFeel = "org.kde.breezedark.desktop";
      };

      # Configure a basic panel with core KDE functionality
      panels = [
        {
          location = "bottom";
          height = 44;
          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.icontasks"
            "org.kde.plasma.systemtray"
            "org.kde.plasma.digitalclock"
          ];
        }
      ];
      
      # Configure the most basic settings directly through config files
      configFile = {
        # Disable Baloo indexing for better performance
        baloofilerc = {
          "Basic Settings" = {
            "Indexing-Enabled" = false;
          };
        };
        
        # Set dark theme
        kdeglobals = {
          General = {
            ColorScheme = "BreezeDark";
          };
          KDE = {
            SingleClick = false;  # Double-click to open files
          };
        };
      };
    };
    
    # Create a simple home directory so home-manager doesn't complain
    home = {
      stateVersion = "23.11";
    };
  };
}

