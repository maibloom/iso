{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.calamares;
  
  # Create a desktop item for Calamares
  calamaresDesktopItem = pkgs.makeDesktopItem {
    name = "calamares";
    desktopName = "Install Bloom NixOS";
    genericName = "System Installer";
    comment = "Install Bloom NixOS to your computer";
    exec = "pkexec ${pkgs.calamares-nixos}/bin/calamares";
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

    # Make sure the user can run Calamares with proper permissions
    security.polkit.enable = true;
    security.sudo.enable = true;
    
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
          
          # Use default branding
          branding: default
          
          # No custom settings, using defaults
          settings: {}
        '';
        mode = "0644";
      };
      
      # Autostart entry for Calamares
      "xdg/autostart/calamares-installer.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Install Bloom NixOS
          GenericName=System Installer
          Comment=Install Bloom NixOS to your computer
          Exec=pkexec ${pkgs.calamares-nixos}/bin/calamares
          Icon=calamares
          Terminal=false
          StartupNotify=true
          Categories=Qt;System;
        '';
        mode = "0644";
      };
    };
    
    # Create a first boot service to set up desktop shortcut
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
          Exec=pkexec ${pkgs.calamares-nixos}/bin/calamares
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
        '';
      };
    };
  };
}
