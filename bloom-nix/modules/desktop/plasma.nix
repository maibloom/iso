# KDE Plasma 6 desktop environment configuration for Bloom Nix
{ config, lib, pkgs, inputs, outputs, ... }:

let
  # Default user for the live system and initial setup
  defaultUser = "bloomnix";
in {
  # Enable X server and Wayland
  services.xserver.enable = true;
  
  # Configure display manager
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;  # Enable Wayland support in SDDM
      theme = "breeze";
      # Enable automatic login without password
      autoLogin = {
        enable = true;
        user = defaultUser;
      };
    };
    # Default to Plasma on Wayland for modern experience
    defaultSession = "plasma"; 
  };

  # Allow automatic login without password
  security.pam.services.sddm.enableKwallet = true;
  security.pam.services.sddm.gnupg.enable = true;

  # Enable KDE Plasma 6
  services.xserver.desktopManager.plasma6.enable = true;

  # Core KDE Plasma 6 packages and applications
  environment.systemPackages = with pkgs; [
    # Core KDE Packages
    kdePackages.plasma-workspace
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
    kdePackages.gwenview      # Image viewer
    
    # Panel Colorizer (from KDE Store)
    kdePackages.plasma-applet-panel-colorizer
    
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
        lookAndFeel = "org.kde.breezedark.desktop";
        wallpaper = "${config._module.args.bloomBranding}/default.jpg";
        theme = "breeze-dark";
      };

      # Configure a bottom panel with the requested layout
      panels = [
        {
          # Panel position and dimensions
          location = "bottom";     # Place at the bottom of the screen
          height = 44;             # 44px tall
          floating = true;         # Use floating style (looks more modern)
          
          # Panel widgets in left-to-right order:
          # Icon-Only Task Manager -> Panel Spacer -> Digital Clock -> 
          # Application Dashboard -> Panel Spacer -> System Tray
          widgets = [
            # 1. Icon-Only Task Manager (left side)
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
                };
              };
            }
            
            # 2. Panel Spacer
            "org.kde.plasma.panelspacer"
            
            # 3. Digital Clock (center)
            {
              name = "org.kde.plasma.digitalclock";
              config = {
                General = {
                  showDate = true;
                };
              };
            }
            
            # 4. Application Dashboard/Kickoff (to the right of center)
            {
              name = "org.kde.plasma.kickoff";
              config = {
                General = {
                  # Use the KDE logo for the launcher
                  icon = "kde";
                };
              };
            }
            
            # 5. Panel Spacer
            "org.kde.plasma.panelspacer"
            
            # 6. System Tray (right side)
            "org.kde.plasma.systemtray"
            
            # 7. Add the Panel Colorizer for the deep purple color #3C0061
            {
              name = "luisbocanegra.panel.colorizer";
              config = {
                General = {
                  backgroundColor = "#3C0061";
                  backgroundOpacity = 100;
                };
              };
            }
          ];
        }
      ];
      
      # Basic configuration file settings
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

        # Set panel colorizer configuration
        plasmarc = {
          Theme = {
            name = "breeze-dark";
          };
        };
      };
    };
    
    # Create a simple home directory configuration
    home = {
      stateVersion = "23.11";
    };
  };
}
