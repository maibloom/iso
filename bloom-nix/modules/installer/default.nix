{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bloom-installer;
in {
  options.services.bloom-installer = {
    enable = mkEnableOption "Bloom Nix web-based installer";

    # Project structure paths
    projectRoot = mkOption {
      type = types.path;
      default = ../../.;
      description = "Path to the root of the Bloom Nix project";
    };

    # Module paths
    modulePaths = {
      base = mkOption {
        type = types.path;
        default = ../base;
        description = "Path to base system configuration modules";
      };

      desktop = mkOption {
        type = types.path;
        default = ../desktop;
        description = "Path to desktop environment configuration modules";
      };

      hardware = mkOption {
        type = types.path;
        default = ../hardware;
        description = "Path to hardware support modules";
      };

      packages = mkOption {
        type = types.path;
        default = ../packages;
        description = "Path to package management modules";
      };

      branding = mkOption {
        type = types.path;
        default = ../branding;
        description = "Path to branding configuration and assets";
      };
    };

    # Configuration for the installed system
    installedSystem = {
      hostConfig = mkOption {
        type = types.path;
        default = ../../hosts/desktop;
        description = "Path to the desktop host configuration";
      };

      enablePlasma6 = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable KDE Plasma 6 in the installed system";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create Python environment with Streamlit
    environment.systemPackages = with pkgs; [
      # Python and Streamlit
      (python3.withPackages (ps: with ps; [
        streamlit
        psutil
        pkgs.python312Packages.pyebus
        pkgs.python312Packages.zdaemon
        requests
      ]))

      # System tools needed for installation
      gparted
      parted
      ntfs3g
      dosfstools
      e2fsprogs
      btrfs-progs
      xfsprogs
      cryptsetup
      lvm2
      util-linux
      coreutils
      procps
      mkpasswd
      nixos-install-tools

      # For the web browser
      kdePackages.plasma-browser-integration
      firefox
    ];

    # Copy installer Python script and helper scripts
    environment.etc = {
      # Main Streamlit installer script
      "bloom-installer/bloom-installer.py" = {
        source = ./bloom-installer.py;
        mode = "0755";
      };

      # Sudo helper for privileged operations
      "bloom-installer/sudo-helper.py" = {
        source = ./sudo-helper.py;
        mode = "0755";
      };

      # Launcher script for the installer
      "bloom-installer/launch-installer.sh" = {
        text = ''
          #!/bin/sh

          # Set up environment variables for the project structure
          export BLOOM_PROJECT_ROOT="${cfg.projectRoot}"
          export BLOOM_MODULE_BASE="${cfg.modulePaths.base}"
          export BLOOM_MODULE_DESKTOP="${cfg.modulePaths.desktop}"
          export BLOOM_MODULE_HARDWARE="${cfg.modulePaths.hardware}"
          export BLOOM_MODULE_PACKAGES="${cfg.modulePaths.packages}"
          export BLOOM_MODULE_BRANDING="${cfg.modulePaths.branding}"
          export BLOOM_HOST_CONFIG="${cfg.installedSystem.hostConfig}"
          export BLOOM_ENABLE_PLASMA6="${toString cfg.installedSystem.enablePlasma6}"

          # Check if installer is already running
          if [ -f /tmp/bloom-installer-running ]; then
            echo "Installer is already running."
            # Open browser to the installer
            firefox http://localhost:8501 &
            exit 0
          fi

          # Create log directory
          mkdir -p /tmp/bloom-installer-logs

          # Start Streamlit in the background
          cd /etc/bloom-installer
          streamlit run bloom-installer.py --server.port 8501 --server.headless true > /tmp/bloom-installer-logs/streamlit.log 2>&1 &

          # Wait for Streamlit to start
          echo "Starting Bloom Nix installer..."
          sleep 3

          # Open browser to the installer
          firefox http://localhost:8501 &

          exit 0
        '';
        mode = "0755";
      };

      # Logo for the installer
      "bloom-installer/logo.png" = {
        source = let
          logoPath = if builtins.pathExists "${cfg.modulePaths.branding}/assets/logo.png"
                    then "${cfg.modulePaths.branding}/assets/logo.png"
                    else "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        in logoPath;
        mode = "0644";
      };
    };

    # Add desktop shortcut for the installer
    systemd.services.bloom-installer-setup = {
      description = "Setup for Bloom Nix Web Installer";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "bloom-installer-setup" ''
          # Create desktop shortcut
          mkdir -p /home/nixos/Desktop
          cat > /home/nixos/Desktop/bloom-installer.desktop << EOF
          [Desktop Entry]
          Type=Application
          Name=Install Bloom Nix
          GenericName=System Installer
          Comment=Install Bloom Nix to your computer
          Exec=sudo /etc/bloom-installer/launch-installer.sh
          Icon=/etc/bloom-installer/logo.png
          Terminal=false
          StartupNotify=true
          Categories=System;
          EOF

          # Make it executable
          chmod +x /home/nixos/Desktop/bloom-installer.desktop

          # Set ownership if nixos user exists
          if id nixos &>/dev/null; then
            chown -R nixos:users /home/nixos/Desktop/bloom-installer.desktop
          fi
        '';
      };
    };

    # Create autostart entry for the installer
    environment.etc."xdg/autostart/bloom-installer.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Install Bloom Nix
        GenericName=System Installer
        Comment=Install Bloom Nix to your computer
        Exec=sudo /etc/bloom-installer/launch-installer.sh
        Icon=/etc/bloom-installer/logo.png
        Terminal=false
        StartupNotify=true
        Categories=System;
      '';
      mode = "0644";
    };

    # Create a welcome notification that launches the installer
    systemd.user.services.bloom-installer-notify = {
      description = "Bloom Nix Installer Notification";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "bloom-installer-notify" ''
          # Give the desktop environment a moment to load
          sleep 5

          # Show notification with an option to install
          ${pkgs.libnotify}/bin/notify-send \
            --app-name="Bloom Nix" \
            --icon=/etc/bloom-installer/logo.png \
            --urgency=normal \
            "Welcome to Bloom Nix!" \
            "Click here to start the installation process." \
            --action=default="Install Now" \
            --hint=string:desktop-entry:bloom-installer

          # If notification is clicked, launch installer
          if [ $? -eq 0 ]; then
            sudo /etc/bloom-installer/launch-installer.sh &
          fi
        '';
      };
    };

    # Allow sudo without password for the installer scripts
    security.sudo.extraConfig = ''
      # Allow nixos user to run the installer without a password
      nixos ALL=(ALL) NOPASSWD: /etc/bloom-installer/launch-installer.sh
      nixos ALL=(ALL) NOPASSWD: /etc/bloom-installer/sudo-helper.py
      nixos ALL=(ALL) NOPASSWD: /usr/bin/python3 /etc/bloom-installer/sudo-helper.py *
    '';

    # Allow passwordless sudo for specific commands needed by the installer
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel") &&
            (action.id === "org.freedesktop.udisks2.filesystem-mount" ||
             action.id === "org.freedesktop.udisks2.filesystem-mount-system" ||
             action.id === "org.freedesktop.udisks2.encrypted-unlock" ||
             action.id === "org.freedesktop.udisks2.encrypted-unlock-system" ||
             action.id.indexOf("org.freedesktop.udisks2.") === 0)) {
          return polkit.Result.YES;
        }
      });
    '';

    # Open firewall for Streamlit (localhost only)
    networking.firewall.allowedTCPPorts = [ 8501 ];

    # Make sure Firefox is installed and configured as the default browser
    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisplayBookmarksToolbar = "always";
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
      };
    };

    # Set the default browser to Firefox
    xdg.mime.defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };
}
