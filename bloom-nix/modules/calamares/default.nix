{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.calamares;
in {
  options.services.calamares = {
    enable = mkEnableOption "Calamares installer";
  };

  config = mkIf cfg.enable {
    # 1. Install Calamares and its dependencies
    environment.systemPackages = with pkgs; [
      calamares-framework
      parted
      gptfdisk
      cryptsetup
      dosfstools
      ntfs3g
      xfsprogs
      btrfs-progs
    ];

    # 2. Make sure the user can run Calamares
    security.polkit.enable = true;
    security.sudo.enable = true;
    
    # 3. Basic Calamares configuration (using defaults)
    environment.etc = {
      # Main Calamares configuration file
      "calamares/settings.conf" = {
        text = ''
          # Configuration file for Calamares
          # Syntax is YAML 1.2
          ---
          # Modules can be job modules (with different interfaces) and view modules.
          # They can be used in the exec and show phases of the sequence, and both
          # phases are split into weighted sequences.
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
      
      # Install script for NixOS
      "calamares/modules/nixos-install.conf" = {
        text = ''
          ---
          # NixOS installation script configuration
          rootMountPoint: /target
          script:
            - command: "nixos-generate-config --root /target"
            - command: "nixos-install --root /target --no-root-passwd"
            - command: "sync"
        '';
        mode = "0644";
      };
      
      # Desktop file to launch Calamares
      "xdg/autostart/calamares.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Install System
          GenericName=System Installer
          Comment=Calamares System Installer
          Exec=pkexec calamares
          Icon=calamares
          Terminal=false
          StartupNotify=true
          Categories=Qt;System;
        '';
        mode = "0644";
      };
    };
    
    # 4. Configure Plasma to auto-start Calamares and pin to taskbar
    # This assumes KDE Plasma is your desktop environment
    plasma.configFile."plasma-org.kde.plasma.desktop-appletsrc" = {
      group = "Containments";
      key = "taskmanager";
      value = {
        launchers = "applications:calamares.desktop";
        pinnedLaunchers = "applications:calamares.desktop";
      };
    };
    
    # 5. Make Calamares run on startup (first boot only)
    systemd.user.services.calamares-autostart = {
      description = "Autostart Calamares installer";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.calamares-framework}/bin/calamares";
        RemainAfterExit = false;
      };
    };
    
    # 6. Build customization for first boot only
    systemd.services.calamares-firstboot = {
      description = "First boot setup for Calamares";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "calamares-firstboot" ''
          # Only run on first boot
          if [ ! -f /var/lib/calamares-firstboot-done ]; then
            # Ensure Calamares starts on first boot
            mkdir -p /etc/xdg/autostart
            cp /etc/xdg/autostart/calamares.desktop /etc/xdg/autostart/
            
            # Mark as done
            touch /var/lib/calamares-firstboot-done
          fi
        '';
      };
    };
  };
}
