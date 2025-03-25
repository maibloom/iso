# Bloom Theme configuration for GNOME
{ config, lib, pkgs, ... }:

let
  defaultUser = "nixos";
in {
  # Create Bloom Theme using runCommand
  nixpkgs.overlays = [
    (final: prev: {
      bloomTheme = prev.runCommand "bloom-theme-1.0.0" {
        # Dependencies for building the theme
        nativeBuildInputs = with prev; [ 
          sassc 
          gtk3
          gtk4
        ];
      } ''
        # Create necessary directories
        mkdir -p $out/share/themes/Bloom-Theme/gnome-shell
        mkdir -p $out/share/themes/Bloom-Theme/gtk-3.0
        mkdir -p $out/share/themes/Bloom-Theme/gtk-4.0
        
        # Create gnome-shell.css with matte black panel
        cat > $out/share/themes/Bloom-Theme/gnome-shell/gnome-shell.css << EOF
        /* Bloom Theme - GNOME Shell Theme */
        
        /* Panel (Top Bar) styling with matte black */
        #panel {
          background-color: rgba(20, 20, 20, 0.95);
          font-size: 11pt;
          height: 2.5em;
          border-bottom: none;
          box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
        }
        
        /* When the panel is in the overview */
        .unlock-screen #panel,
        .login-screen #panel,
        #panel.unlock-screen,
        #panel.login-screen {
          background-color: rgba(20, 20, 20, 0.95);
        }
        
        /* Override panel transparency when a window is maximized */
        #panel.solid {
          background-color: rgba(20, 20, 20, 0.95);
        }
        EOF
        
        # Create GTK3 theme
        cat > $out/share/themes/Bloom-Theme/gtk-3.0/gtk.css << EOF
        /* Bloom Theme - GTK3 Theme */
        
        /* Include the base Adwaita theme */
        @import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained.css");
        
        /* Customize headerbar */
        headerbar {
          background-color: #141414;
          border-color: #141414;
          border-bottom: none;
        }
        
        /* Ensure buttons are visible */
        button.titlebutton {
          opacity: 1;
          transition: opacity 0.3s;
        }
        
        /* Window control buttons */
        button.titlebutton.close {
          color: #ff5555;
        }
        
        button.titlebutton.maximize {
          color: #55ff55;
        }
        
        button.titlebutton.minimize {
          color: #ffff55;
        }
        EOF
        
        # Create GTK4 theme
        cat > $out/share/themes/Bloom-Theme/gtk-4.0/gtk.css << EOF
        /* Bloom Theme - GTK4 Theme */
        
        /* Include base Adwaita GTK4 theme */
        @import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk.css");
        
        /* Customize headerbar */
        headerbar {
          background-color: #141414;
          color: #ffffff;
          border-bottom: none;
          box-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
        }
        
        /* Ensure window control buttons are visible */
        .titlebutton {
          opacity: 1;
          transition: opacity 0.3s;
        }
        
        /* Window control buttons */
        .titlebutton.close {
          color: #ff5555;
        }
        
        .titlebutton.maximize {
          color: #55ff55;
        }
        
        .titlebutton.minimize {
          color: #ffff55;
        }
        EOF
        
        # Create theme metadata
        cat > $out/share/themes/Bloom-Theme/index.theme << EOF
        [Desktop Entry]
        Type=X-GNOME-Metatheme
        Name=Bloom-Theme
        Comment=Custom theme for Bloom Nix
        Encoding=UTF-8
        
        [X-GNOME-Metatheme]
        GtkTheme=Bloom-Theme
        MetacityTheme=Bloom-Theme
        IconTheme=Adwaita
        CursorTheme=Adwaita
        ButtonLayout=appmenu:minimize,maximize,close
        EOF
      '';
    })
  ];
  
  # Add our theme package to system packages
  environment.systemPackages = with pkgs; [
    bloomTheme
    
    # Ensure GNOME extensions are installed
    gnomeExtensions.user-themes
    gnomeExtensions.dash-to-panel
    gnomeExtensions.just-perfection
    gnomeExtensions.blur-my-shell
  ];
  
  # Make our theme available to GNOME Shell
  environment.pathsToLink = [ 
    "/share/themes" 
  ];
  
  # Enable dconf
  programs.dconf.enable = true;
  
  # Create dconf files for system-wide settings
  # This method works on older NixOS versions too
  environment.etc = {
    # User profile to chain the databases
    "dconf/profile/user".text = ''
      user-db:user
      system-db:local
    '';
    
    # GDM profile
    "dconf/profile/gdm".text = ''
      user-db:user
      system-db:gdm
      system-db:local
    '';
    
    # Basic theme settings
    "dconf/db/local.d/01-bloom-theme".text = ''
      [org/gnome/desktop/wm/preferences]
      button-layout='appmenu:minimize,maximize,close'
      focus-mode='click'
      action-double-click-titlebar='toggle-maximize'
      
      [org/gnome/desktop/interface]
      enable-hot-corners=true
      gtk-theme='Bloom-Theme'
      icon-theme='Adwaita'
      cursor-theme='Adwaita'
      font-name='Noto Sans 11'
      document-font-name='Noto Sans 11'
      monospace-font-name='Fira Code 10'
    '';
    
    # Shell settings
    "dconf/db/local.d/02-shell-settings".text = ''
      [org/gnome/shell]
      disable-user-extensions=false
      favorite-apps=['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'firefox.desktop', 'org.gnome.gedit.desktop']
      enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-panel@jderose9.github.com', 'just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']
    '';
    
    # Mutter settings
    "dconf/db/local.d/03-mutter-settings".text = ''
      [org/gnome/mutter]
      edge-tiling=true
      workspaces-only-on-primary=true
    '';
    
    # Extension settings
    "dconf/db/local.d/04-extension-settings".text = ''
      [org/gnome/shell/extensions/user-theme]
      name='Bloom-Theme'
      
      [org/gnome/shell/extensions/dash-to-panel]
      intellihide=false
      autohide=false
      panel-color='rgba(20, 20, 20, 0.95)'
      panel-opacity=95
      panel-size=48
      panel-positions={'0': 'TOP'}
      panel-element-positions={"0":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centered"},{"element":"centerBox","visible":true,"position":"centered"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}
      appicon-margin=8
      appicon-padding=4
      dot-position='BOTTOM'
      animate-appicon-hover=true
      animate-appicon-hover-animation-extent=4
      
      [org/gnome/shell/extensions/just-perfection]
      hot-corner=true
      startup-status=0
      animation=1
      activities-button=false
      
      [org/gnome/shell/extensions/blur-my-shell]
      panel-blur=true
      panel-blur-strength=4
    '';
    
    # GDM theme settings
    "dconf/db/gdm.d/01-bloom-theme".text = ''
      [org/gnome/desktop/interface]
      gtk-theme='Bloom-Theme'
      icon-theme='Adwaita'
      cursor-theme='Adwaita'
      font-name='Noto Sans 11'
      
      [org/gnome/desktop/wm/preferences]
      button-layout='appmenu:minimize,maximize,close'
    '';
  };
  
  # Configure GDM
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  
  # Set the theme preference for the default user through home-manager
  home-manager.users.${defaultUser} = { pkgs, ... }: {
    # Ensure default user gets the theme too
    dconf.settings = {
      "org/gnome/shell" = {
        "enabled-extensions" = [
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "dash-to-panel@jderose9.github.com"
          "just-perfection-desktop@just-perfection"
          "blur-my-shell@aunetx"
        ];
      };
      
      "org/gnome/shell/extensions/user-theme" = {
        "name" = "Bloom-Theme";
      };
      
      "org/gnome/desktop/interface" = {
        "gtk-theme" = "Bloom-Theme";
      };
    };
    
    home.stateVersion = "23.11";
  };
  
  # System activation script to make the theme available system-wide
  system.activationScripts.bloomThemeSetup = ''
    # Create symlinks to make the theme available system-wide
    mkdir -p /run/current-system/sw/share/themes/
    ln -sf ${pkgs.bloomTheme}/share/themes/Bloom-Theme /run/current-system/sw/share/themes/
    
    # Update dconf database
    dconf update || true
  '';
}
