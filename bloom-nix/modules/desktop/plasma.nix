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
    # Core KDE Packages (using kdePackages instead of plasma5Packages)
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
      
      # Global theme settings
      workspace = {
        theme = "breeze-dark";
        colorScheme = "BreezeDark";
        lookAndFeel = "org.kde.breezedark.desktop";
        
        # Use the branded wallpaper from Bloom Nix
        wallpaper = "${config._module.args.bloomBranding}/default.jpg";
        
        # Icon and cursor themes
        iconTheme = "breeze-dark";
        cursor = {
          theme = "Breeze";
          size = 24;
        };
      };

      # Define panels - one centered dock at the bottom (macOS/Windows 11 style)
      panels = [
        {
          location = "bottom";
          height = 44;  # A bit taller for better touch targets
          floating = true;  # Make it float like macOS
          alignment = "center";  # Center the panel
          widgets = [
            # Application launcher (start menu)
            {
              name = "org.kde.plasma.kickoff";
              config = {
                General = {
                  icon = "bloom-nix-logo";  # Use Bloom Nix logo
                  favoritesPortedToKAstats = true;
                };
              };
            }
            
            # Centered task manager (like macOS/Windows 11)
            {
              name = "org.kde.plasma.icontasks";
              config = {
                General = {
                  launchers = [
                    "applications:org.kde.dolphin.desktop"
                    "applications:org.kde.konsole.desktop"
                    "applications:brave-browser.desktop"
                    "applications:org.kde.kate.desktop"
                  ];
                  indicateAudioStreams = true;
                  fill = false;  # Don't let it fill the whole panel
                  maxStripes = 1;  # Single row of icons
                  showOnlyCurrentScreen = true;
                  showOnlyCurrentDesktop = false;
                  showToolTips = true;
                };
              };
            }
            
            # System tray with frequently used items
            {
              name = "org.kde.plasma.systemtray";
              config = {
                General = {
                  extraItems = "org.kde.plasma.battery,org.kde.plasma.networkmanagement,org.kde.plasma.bluetooth,org.kde.plasma.volume";
                  knownItems = "org.kde.plasma.battery,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.volume,org.kde.plasma.bluetooth";
                };
              };
            }
            
            # Digital clock
            {
              name = "org.kde.plasma.digitalclock";
              config = {
                General = {
                  showDate = true;
                  showSeconds = false;
                  use24hFormat = false;
                };
              };
            }
          ];
        }
      ];
      
      # Configure window behavior and appearance
      kwin = {
        # Set up some sensible window rules
        rules = [
          {
            description = "Application Settings";
            types = ["normal"];
            properties = {
              # Modern minimalist window decoration
              borderSize = 1;
              windowRadius = 8;
            };
          }
        ];
      };
      
      # Configure shortcuts
      shortcuts = {
        kwin = {
          "Expose" = "Meta+Tab";  # Overview with Meta+Tab
          "Show Desktop" = "Meta+D";
          "Switch to Next Desktop" = "Meta+Right";
          "Switch to Previous Desktop" = "Meta+Left";
        };
      };
      
      # Configure low-level settings directly
      configFile = {
        # Disable Baloo indexing for better performance
        baloofilerc."Basic Settings"."Indexing-Enabled" = false;
        
        # Configure the Breeze Dark theme
        kdeglobals = {
          General = {
            ColorScheme = "BreezeDark";
            accentColorFromWallpaper = false;
          };
          "KDE".SingleClick = false;  # Double-click to open files
        };
        
        # Configure desktop effects
        kwinrc = {
          Compositing = {
            GLCore = true;
            Backend = "OpenGL";
            Enabled = true;
            LatencyPolicy = "Low";
          };
          
          # Configure virtual desktops
          Desktops = {
            Name_1 = "Main";
            Name_2 = "Work";
            Name_3 = "Web";
            Name_4 = "Media";
            Number = 4;
            Rows = 1;
          };
          
          # Configure effect animations - proper structure
          Plugins = {
            blurEnabled = true;
            contrastEnabled = true;
            slidingpopupsEnabled = true;
            kwin4_effect_fadeEnabled = true;
            kwin4_effect_fadedesktopEnabled = true;
          };
        };
      };
    };
  };
}
