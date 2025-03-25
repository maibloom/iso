# Bloom Theme configuration for GNOME
{ config, lib, pkgs, ... }:

let
  defaultUser = "nixos";
in {
  # Create Bloom Theme package as a derivation
  nixpkgs.overlays = [
    (final: prev: {
      bloomTheme = prev.stdenv.mkDerivation {
        name = "bloom-theme";
        version = "1.0.0";
        
        # No source, we're creating files directly
        src = prev.writeTextFile {
          name = "empty";
          text = "";
        };
        
        # Dependencies for building the theme
        nativeBuildInputs = with prev; [ 
          sassc 
          gtk3
          gtk4
        ];
        
        # Build phase creates theme directories and files
        buildPhase = ''
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
        
        # Install phase - nothing needed, files are already in $out
        installPhase = "echo 'Theme installed.'";
      };
    })
  ];
  
  # Add our theme package to system packages
  environment.systemPackages = with pkgs; [
    bloomTheme
  ];
  
  # Make our theme available to GNOME Shell
  environment.pathsToLink = [ 
    "/share/themes" 
    "/share/backgrounds"
  ];
  
  # Link the theme into the main system paths to ensure it's available system-wide
  system.activationScripts.bloomTheme = ''
    # Create symlinks to make the theme available system-wide
    mkdir -p /run/current-system/sw/share/themes/
    ln -sf ${pkgs.bloomTheme}/share/themes/Bloom-Theme /run/current-system/sw/share/themes/
  '';
  
  # Create system-wide dconf profile and database
  environment.etc."dconf/profile/user".text = ''
    user-db:user
    system-db:bloom
  '';
  
  # Create the system database with our default settings
  environment.etc."dconf/db/bloom.d/01-bloom-theme".text = ''
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
    
    [org/gnome/shell]
    disable-user-extensions=false
    favorite-apps=['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'firefox.desktop', 'org.gnome.gedit.desktop']
    
    [org/gnome/shell/extensions]
    disabled-extensions=[]
    
    [org/gnome/mutter]
    edge-tiling=true
    workspaces-only-on-primary=true
    
    [org/gnome/desktop/background]
    picture-options='zoom'
  '';
  
  # Create a extensions settings database
  environment.etc."dconf/db/bloom.d/02-extensions".text = ''
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
  
  # Auto-enable required extensions for all users
  environment.etc."dconf/db/bloom.d/00-extensions-enabled".text = ''
    [org/gnome/shell]
    enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-panel@jderose9.github.com', 'just-perfection-desktop@just-perfection', 'blur-my-shell@aunetx']
  '';
  
  # Create a system-wide initial setup script that runs at first boot
  system.activationScripts.gnomeSetup = ''
    # Update dconf databases
    dconf update
    
    # Setup for GDM (Login screen)
    if [ ! -d /run/current-system/sw/share/gdm/greeter/themes/Bloom-Theme ]; then
      mkdir -p /run/current-system/sw/share/gdm/greeter/themes/Bloom-Theme
      cp -r ${pkgs.bloomTheme}/share/themes/Bloom-Theme/gnome-shell/* /run/current-system/sw/share/gdm/greeter/themes/Bloom-Theme/
      chmod -R 755 /run/current-system/sw/share/gdm/greeter/themes/Bloom-Theme
    fi
  '';
  
  # Configure GDM to use our theme
  services.xserver.displayManager.gdm.extraConfig = ''
    [org.gnome.shell]
    disable-user-extensions=false
    enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com']
    
    [org.gnome.shell.extensions.user-theme]
    name='Bloom-Theme'
  '';
  
  # Set the theme preference for the default user too through home-manager
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
      
      # Set wallpaper - preferably from the Bloom branding if available
      "org/gnome/desktop/background" = {
        "picture-uri" = lib.mkDefault "file:///run/current-system/sw/share/backgrounds/gnome/adwaita-d.jpg";
        "picture-uri-dark" = lib.mkDefault "file:///run/current-system/sw/share/backgrounds/gnome/adwaita-d.jpg";
      };
    };
    
    home = {
      stateVersion = "23.11";
    };
  };
  
  # Configure system shell script to run once at first boot to ensure everything is set up correctly
  system.activationScripts.finalSetup = ''
    #!/bin/sh
    
    # Script to run at first boot to ensure theme is properly applied
    cat > /etc/nixos/theme-setup.sh << 'EOF'
    #!/bin/sh
    
    # Force update dconf database
    dconf update
    
    # Compile schemas to ensure our theme is recognized
    glib-compile-schemas /run/current-system/sw/share/glib-2.0/schemas
    
    # Force GDM to reload theme
    if systemctl is-active gdm.service >/dev/null; then
      systemctl restart gdm.service
    fi
    
    # Set default theme for all users (including future users)
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        # Create .config directory if it doesn't exist
        mkdir -p "$USER_HOME/.config/dconf"
        chown $USER:users "$USER_HOME/.config/dconf"
        
        # Set theme for the user
        sudo -u $USER gsettings set org.gnome.desktop.interface gtk-theme 'Bloom-Theme'
        sudo -u $USER gsettings set org.gnome.shell.extensions.user-theme name 'Bloom-Theme'
      fi
    done
    EOF
    
    chmod +x /etc/nixos/theme-setup.sh
    
    # Create systemd service that runs the script at first boot
    cat > /etc/systemd/system/bloom-theme-setup.service << EOF
    [Unit]
    Description=Set up Bloom Theme for GNOME
    After=multi-user.target
    
    [Service]
    Type=oneshot
    ExecStart=/etc/nixos/theme-setup.sh
    RemainAfterExit=true
    
    [Install]
    WantedBy=multi-user.target
    EOF
    
    # Enable the service to run at boot
    systemctl enable bloom-theme-setup.service
  '';
}
