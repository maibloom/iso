{ config, lib, pkgs, ... }:

let
  # Define the path to your branding directory
  brandingDir = ../branding;
in {
  # This is the main home-manager configuration for KDE Plasma
  # Import from home-manager's configuration
  
  # Make sure to set this to your appropriate NixOS version
  home.stateVersion = "23.11";
  
  # Import the theme configuration
  imports = [
    ./plasma-theme.nix
  ];

  # Enable Plasma integration for home-manager
  programs.plasma = {
    enable = true;

    # =======================================================
    # Custom keyboard shortcuts
    # =======================================================
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Launch Terminal";
        key = "Meta+Alt+T";
        command = "konsole";
      };
      "launch-browser" = {
        name = "Launch Web Browser";
        key = "Meta+Alt+B";
        command = "firefox";
      };
      "launch-filemanager" = {
        name = "Launch File Manager";
        key = "Meta+Alt+F";
        command = "dolphin";
      };
      "screenshot" = {
        name = "Take Screenshot";
        key = "Print";
        command = "spectacle";
      };
    };

    # =======================================================
    # Desktop widgets configuration
    # =======================================================
    desktop.widgets = [
      # Digital clock widget in the center of the desktop
      {
        digitalClock = {
          position = {
            horizontal = 50; # Center horizontally (percentage)
            vertical = 10;   # Near the top (percentage)
          };
          size = {
            width = 300;
            height = 120;
          };
          # Clock configuration
          showDate = true;
          showSeconds = false;
          dateFormat = "longDate";
          time.format = "24h";
        };
      }
      
      # System monitor widget
      {
        systemMonitor = {
          position = {
            horizontal = 85;
            vertical = 15;
          };
          size = {
            width = 250;
            height = 250;
          };
          # Display CPU and memory usage
          showCpuMonitor = true;
          showMemoryMonitor = true;
          showNetworkMonitor = true;
        };
      }
      
      # Folder view widget for quick access to documents
      {
        folderView = {
          position = {
            horizontal = 20;
            vertical = 75;
          };
          url = "file:///home/$USER/Documents";
          size = {
            width = 400;
            height = 300;
          };
        };
      }
      
      # Notes widget
      {
        notes = {
          position = {
            horizontal = 80;
            vertical = 75;
          };
          size = {
            width = 250;
            height = 250;
          };
        };
      }
    ];

    # =======================================================
    # Panel configuration
    # =======================================================
    panels = [
      # Bottom panel (Windows-like taskbar)
      {
        location = "bottom";
        height = 38;
        widgets = [
          # Application launcher with Bloom logo
          {
            kickoff = {
              icon = "${brandingDir}/bloom-logo.png";
              sortAlphabetically = true;
              showAppsByName = true;
            };
          }
          
          # Task manager with pinned applications
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:org.kde.konsole.desktop"
                "applications:firefox.desktop"
                "applications:org.kde.kate.desktop"
              ];
              showOnlyCurrentDesktop = false;
              showOnlyCurrentActivity = true;
              groupingStrategy = "launcher";
            };
          }
          
          # Add a spacer to push the system tray to the right
          "org.kde.plasma.panelspacer"
          
          # Digital clock
          {
            digitalClock = {
              showDate = true;
              dateFormat = "shortDate";
              showSeconds = false;
              time.format = "24h";
              calendar.firstDayOfWeek = "monday";
            };
          }
          
          # System tray with selected items
          {
            systemTray = {
              items = {
                shown = [
                  "org.kde.plasma.battery"
                  "org.kde.plasma.bluetooth"
                  "org.kde.plasma.clipboard"
                  "org.kde.plasma.devicenotifier"
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.volume"
                ];
                hidden = [
                  "org.kde.plasma.mediacontroller"
                ];
              };
            };
          }
        ];
        # Panel behavior - auto-hide when not needed
        hiding = "autohide";
      },
      
      # Top panel for global menu and window controls
      {
        location = "top";
        height = 28;
        widgets = [
          # Application menu (like macOS)
          "org.kde.plasma.appmenu"
          
          # Application title bar for the active window
          {
            applicationTitleBar = {
              behavior = {
                activeTaskSource = "activeTask";
              };
              layout = {
                elements = [ "appName" "separator" "windowTitle" ];
                horizontalAlignment = "left";
                verticalAlignment = "center";
              };
              windowTitle = {
                font = {
                  bold = false;
                  size = 10;
                };
                source = "appName";
              };
            };
          }
          
          # Spacer to push the next items to the right
          "org.kde.plasma.panelspacer"
          
          # Media player controls
          {
            mediaPlayer = {
              showAlbumArt = true;
              showPlaybackControls = true;
            };
          }
        ];
      }
    ];

    # =======================================================
    # Window rules for specific applications
    # =======================================================
    window-rules = [
      # Make Dolphin open maximized without borders
      {
        description = "Dolphin Configuration";
        match = {
          window-class = {
            value = "dolphin";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
        apply = {
          noborder = {
            value = true;
            apply = "force";
          };
          maximizehoriz = true;
          maximizevert = true;
        };
      },
      
      # Keep terminal windows at a specific size
      {
        description = "Konsole Configuration";
        match = {
          window-class = {
            value = "konsole";
            type = "substring";
          };
        };
        apply = {
          size = {
            value = "900,600";
            apply = "force";
          };
          screen = {
            value = "0";
            apply = "force"; 
          };
          center = true;
        };
      },
      
      # Keep Firefox on a specific desktop
      {
        description = "Firefox on Web Desktop";
        match = {
          window-class = {
            value = "firefox";
            type = "substring";
          };
        };
        apply = {
          desktop = {
            value = "2"; # Desktop 2 (counting from 1)
            apply = "force";
          };
        };
      }
    ];

    # =======================================================
    # Power management configuration
    # =======================================================
    powerdevil = {
      # Settings when on AC power
      AC = {
        powerButtonAction = "lockScreen";
        autoSuspend = {
          idleTimeout = 1800; # 30 minutes
          action = "suspend";
        };
        turnOffDisplay = {
          idleTimeout = 300;  # 5 minutes
          idleTimeoutWhenLocked = "immediately";
        };
      };
      
      # Settings when on battery
      battery = {
        powerButtonAction = "suspend";
        autoSuspend = {
          idleTimeout = 900;  # 15 minutes
          action = "suspend";
        };
        turnOffDisplay = {
          idleTimeout = 180;  # 3 minutes
        };
        dimDisplay = {
          idleTimeout = 120;  # 2 minutes
        };
      };
      
      # Settings for low battery
      lowBattery = {
        autoSuspend = {
          idleTimeout = 300;  # 5 minutes
          action = "suspend";
        };
        whenCritical = "hibernate";
      };
    };

    # =======================================================
    # KWin (window manager) configuration
    # =======================================================
    kwin = {
      # Disable edge behaviors introduced in newer Plasma versions
      edgeBarrier = 0;
      cornerBarrier = false;
      
      # Enable useful KWin scripts
      scripts = {
        polonium.enable = true;  # Tiling window manager functionality
        krohnkite.enable = false; # Alternative tiling window manager
      };
      
      # Configure virtual desktops
      desktops = {
        count = 4;
        rows = 2;
        textLabels = [
          "Main"
          "Web"
          "Dev"
          "Media"
        ];
      };
    };

    # =======================================================
    # Screen locker configuration
    # =======================================================
    kscreenlocker = {
      lockOnResume = true;
      timeout = 300;  # 5 minutes
      wallpaperPlugin = "org.kde.image";
      wallpaperMode = "crop";
      wallpaperPath = "${brandingDir}/login-background.png";
    };

    # =======================================================
    # Configure keyboard shortcuts
    # =======================================================
    shortcuts = {
      ksmserver = {
        "Lock Session" = [
          "Screensaver"
          "Meta+Ctrl+Alt+L"
        ];
      };

      kwin = {
        # Virtual desktop navigation
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        
        # Window navigation (vim-like)
        "Switch Window Down" = "Meta+J";
        "Switch Window Left" = "Meta+H";
        "Switch Window Right" = "Meta+L";
        "Switch Window Up" = "Meta+K";
        
        # Window manipulation
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window Close" = "Meta+Q";
        "Window Fullscreen" = "Meta+F";
        
        # Desktop effects
        "Expose" = "Meta+Tab";
        "Show Desktop Grid" = "Meta+G";
      };
    };

    # =======================================================
    # Low-level KDE configuration files
    # =======================================================
    configFile = {
      # Disable file indexing to improve performance
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      
      # Configure virtual desktops (force 4 desktops)
      kwinrc.Desktops = {
        Number = {
          value = 4;
          immutable = true;  # Prevent changes through System Settings
        };
        Rows = 2;
      };
      
      # Configure Dolphin file manager
      dolphinrc = {
        # Configure toolbar and menu items
        "KFileDialog Settings" = {
          ShowBookmarks = true;
          ShowFilterButton = true;
          ShowFullPath = false;
        };
        
        # Show hidden files by default
        "General".ShowHiddenFiles = false;
        
        # Configure default view properties
        "PreviewSettings".Plugins = [
          "audiothumbnail"
          "imagethumbnail" 
          "jpegthumbnail"
          "svgthumbnail"
          "ffmpegthumbs"
        ];
      };
      
      # Configure custom key bindings for applications
      "kglobalshortcutsrc"."kwin"."Switch to Desktop 1" = "Meta+1,Meta+1,Switch to Desktop 1";
      
      # Configure the screen locker
      kscreenlockerrc = {
        Greeter.WallpaperPlugin = "org.kde.image";
        "Greeter/Wallpaper/org.kde.image/General".Image = "${brandingDir}/login-background.png";
      };
    };
  };
  
  # Add any additional home-manager configurations here
  programs.bash.enable = true;
  programs.git.enable = true;
}
