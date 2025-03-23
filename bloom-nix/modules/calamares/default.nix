{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.calamares;
  
  # Create a desktop item for Calamares that doesn't require password
  calamaresDesktopItem = pkgs.makeDesktopItem {
    name = "calamares";
    desktopName = "Install Bloom NixOS";
    genericName = "System Installer";
    comment = "Install Bloom NixOS to your computer";
    # Direct execution without pkexec (will be handled by polkit rules)
    exec = "${pkgs.calamares-nixos}/bin/calamares";
    icon = "calamares";
    terminal = false;
    categories = [ "Qt" "System" ];
  };
in {
  options.services.calamares = {
    enable = mkEnableOption "Calamares installer";
  };

  config = mkIf cfg.enable {
    # Install Calamares and its dependencies
    environment.systemPackages = with pkgs; [
      # Main Calamares package for NixOS
      calamares-nixos
      
      # Optional: additional NixOS-specific extensions
      calamares-nixos-extensions
      
      # Dependencies for partitioning and filesystem operations
      parted
      gptfdisk
      cryptsetup
      dosfstools
      ntfs3g
      xfsprogs
      btrfs-progs
      
      # Our custom desktop launcher
      calamaresDesktopItem
    ];

    # Enable polkit but configure it to not require passwords
    security.polkit.enable = true;
    security.sudo.enable = true;
    
    # Add a PolicyKit rule to allow the live user to run Calamares without authentication
    security.polkit.extraConfig = ''
      /* Allow the live user to run Calamares without password */
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.policykit.exec" ||
             action.id == "org.libcalamares.calamares.pkexec.run") &&
            subject.local && subject.active && subject.isInGroup("users")) {
            return polkit.Result.YES;
        }
      });
    '';
    
    # Basic Calamares configuration (using defaults)
    environment.etc = {
      # Main Calamares configuration file
      "calamares/settings.conf" = {
        text = ''
          # Configuration file for Calamares
          # Syntax is YAML 1.2
          ---
          # Define module search paths
          modules-search: [ local, /run/current-system/sw/lib/calamares/modules ]

          # Phase 1: show UI and prepare for installation
          sequence:
          - show:
            - welcome
            - locale
            - keyboard
            - partition
            - users
            - summary
          
          # Phase 2: do the installation
          - exec:
            - partition
            - mount
            - unpackfs
            - networkcfg
            - machineid
            - fstab
            - locale
            - keyboard
            - localecfg
            - users
            - displaymanager
            - networkcfg
            - hwclock
            - services-systemd
            - bootloader-config
            - bootloader
            - packages
            - umount
          
          # Use our custom branding
          branding: bloom-nix
          
          # No custom settings, using defaults
          settings: {}
        '';
        mode = "0644";
      };
      
      # Custom branding configuration
      "calamares/branding/bloom-nix/branding.desc" = {
        text = ''
          ---
          componentName: bloom-nix
          
          strings:
              productName:         Bloom NixOS
              shortProductName:    Bloom
              version:             1.0.0
              shortVersion:        1.0
              versionedName:       Bloom NixOS 1.0.0
              shortVersionedName:  Bloom 1.0
              bootloaderEntryName: Bloom NixOS
              productUrl:          https://github.com/yourusername/bloom-nix
              supportUrl:          https://github.com/yourusername/bloom-nix/issues
          
          images:
              productLogo:         "logo.png"
              productIcon:         "logo.png"
              # Uncomment and add a welcome image when available:
              # productWelcome:    "welcome.png"
          
          slideshow:             "show.qml"
          
          style:
              sidebarBackground:    "#FF5733"
              sidebarText:          "#FFFFFF"
              sidebarTextSelect:    "#000d33"
              sidebarTextHighlight: "#000d33"
          
          # These options are for the Welcome page
          welcomeStyleCalamares:    false
          welcomeExpandingLogo:     true
        '';
        mode = "0644";
      };
      
      # Simple QML slideshow
      "calamares/branding/bloom-nix/show.qml" = {
        text = ''
          import QtQuick 2.0;
          import calamares.slideshow 1.0;

          Presentation {
              id: presentation

              Timer {
                  interval: 20000
                  running: true
                  repeat: true
                  onTriggered: presentation.goToNextSlide()
              }

              Slide {
                  Image {
                      id: background1
                      source: "logo.png" // Using logo since welcome.png is not available yet
                      width: 800
                      height: 600
                      fillMode: Image.PreserveAspectFit
                      anchors.centerIn: parent
                  }
                  Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      anchors.top: background1.bottom
                      text: "Welcome to Bloom NixOS"
                      wrapMode: Text.WordWrap
                      width: 800
                      horizontalAlignment: Text.Center
                      color: "#000d33"
                      font.pixelSize: 24
                  }
              }

              Slide {
                  Text {
                      anchors.centerIn: parent
                      text: "Thank you for choosing Bloom NixOS.\n\nThe installation will begin shortly."
                      wrapMode: Text.WordWrap
                      width: 800
                      horizontalAlignment: Text.Center
                      color: "#000d33"
                      font.pixelSize: 22
                  }
              }
          }
        '';
        mode = "0644";
      };
      
      # Add specific polkit policy file for Calamares
      "polkit-1/rules.d/49-nopasswd-calamares.rules" = {
        text = ''
          /* Allow live user to run Calamares without password */
          polkit.addRule(function(action, subject) {
            if ((action.id == "org.freedesktop.policykit.exec" ||
                 action.id == "org.libcalamares.calamares.pkexec.run") &&
                subject.local && subject.active && subject.isInGroup("users")) {
                return polkit.Result.YES;
            }
          });
        '';
        mode = "0644";
      };
      
      # Autostart entry for Calamares (no pkexec)
      "xdg/autostart/calamares-installer.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Install Bloom NixOS
          GenericName=System Installer
          Comment=Install Bloom NixOS to your computer
          Exec=${pkgs.calamares-nixos}/bin/calamares
          Icon=calamares
          Terminal=false
          StartupNotify=true
          Categories=Qt;System;
        '';
        mode = "0644";
      };
    };
    
    # Allow sudo without password for the live user
    security.sudo.extraConfig = ''
      # Allow 'nixos' user to run Calamares without a password
      nixos ALL=(ALL) NOPASSWD: ${pkgs.calamares-nixos}/bin/calamares
      # Allow any user in the 'wheel' group to run Calamares without a password
      %wheel ALL=(ALL) NOPASSWD: ${pkgs.calamares-nixos}/bin/calamares
    '';
    
    # Create a first boot service to set up desktop shortcut and copy branding assets
    systemd.services.calamares-setup = {
      description = "Setup for Calamares installer";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "calamares-setup" ''
          # Create desktop icon on first boot
          mkdir -p /home/nixos/Desktop
          cat > /home/nixos/Desktop/calamares.desktop << EOF
          [Desktop Entry]
          Type=Application
          Name=Install Bloom NixOS
          GenericName=System Installer
          Comment=Install Bloom NixOS to your computer
          Exec=${pkgs.calamares-nixos}/bin/calamares
          Icon=calamares
          Terminal=false
          StartupNotify=true
          Categories=Qt;System;
          EOF
          
          # Make it executable
          chmod +x /home/nixos/Desktop/calamares.desktop
          
          # Set ownership if nixos user exists
          if id nixos &>/dev/null; then
            chown -R nixos:users /home/nixos/Desktop/calamares.desktop
          fi
          
          # Create branding directory 
          mkdir -p /etc/calamares/branding/bloom-nix
          
          # Find the module's branding assets directory
          ASSETS_DIR=$(find /nix/store -path "*/modules/branding/assets" -type d | head -n 1)
          
          if [ -n "$ASSETS_DIR" ] && [ -f "$ASSETS_DIR/logo.png" ]; then
            # Copy logo to Calamares branding directory
            cp "$ASSETS_DIR/logo.png" /etc/calamares/branding/bloom-nix/logo.png
            echo "Successfully copied logo from $ASSETS_DIR to Calamares branding directory"
          else
            echo "Warning: Could not find logo.png in the modules/branding/assets directory"
          fi
          
          # Note: Welcome image handling has been removed as it's commented out in the config
          
          # Set proper permissions
          chmod -R 644 /etc/calamares/branding/bloom-nix/*
        '';
      };
    };
  };
}
