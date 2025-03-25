# Bloom Theme configuration for GNOME - Minimalist Approach
{ config, lib, pkgs, ... }:

let
  defaultUser = "nixos";
in {
  # Create Bloom Theme package
  nixpkgs.overlays = [
    (final: prev: {
      bloomTheme = prev.runCommand "bloom-theme-1.0.0" {
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
  
  # Install the theme package and GNOME extensions
  environment.systemPackages = with pkgs; [
    bloomTheme
    gnomeExtensions.user-themes
    gnomeExtensions.dash-to-panel
    gnomeExtensions.just-perfection
    gnomeExtensions.blur-my-shell
    
    # Add gsettings command to manipulate GNOME settings
    glib
  ];
  
  # Make our theme available to GNOME Shell
  environment.pathsToLink = [ 
    "/share/themes" 
  ];
  
  # Enable dconf (basic setting only)
  programs.dconf.enable = true;
  
  # Configure GDM 
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  
  # Set the theme for the default user through home-manager
  home-manager.users.${defaultUser} = { pkgs, ... }: {
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
  
  # This script will be used to setup default GNOME settings when the system boots
  # Note: We use /usr/bin/env because the script will be executed in the system context
  environment.etc."bloomtheme-setup.sh" = {
    text = ''
      #!/usr/bin/env bash
      
      # Set system-wide theme
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Bloom-Theme'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface enable-hot-corners true
      
      # Configure mutter (window manager)
      ${pkgs.glib}/bin/gsettings set org.gnome.mutter edge-tiling true
      
      # Enable extensions
      ${pkgs.glib}/bin/gsettings set org.gnome.shell disable-user-extensions false
      ${pkgs.glib}/bin/gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-panel@jderose9.github.com', 'just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']"
      
      # Configure dash-to-panel extension
      ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-panel intellihide false
      ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-panel autohide false
      ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 48
      
      # Configure Just Perfection extension
      ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.just-perfection hot-corner true
      ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.just-perfection activities-button false
      
      # Set shell theme
      ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.user-theme name 'Bloom-Theme'
    '';
    mode = "0755";
  };
  
  # Create a systemd service to run our script on startup for all users
  systemd.user.services.bloom-theme-setup = {
    description = "Setup Bloom Theme for GNOME";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/bloomtheme-setup.sh";
      RemainAfterExit = true;
    };
  };
  
  # System activation script only for making the theme available in the filesystem
  system.activationScripts.bloomThemeSetup = ''
    # Create symlinks to make the theme available system-wide
    mkdir -p /run/current-system/sw/share/themes/
    ln -sf ${pkgs.bloomTheme}/share/themes/Bloom-Theme /run/current-system/sw/share/themes/
  '';
}
