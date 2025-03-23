# modules/calamares/nix-installer-support.nix
# This module provides the necessary support for Calamares to install a Nix-based system
{ config, lib, pkgs, ... }:

{
  # Create Nix-specific configuration for Calamares
  environment.etc."calamares/modules/nix-support.conf".text = ''
    # Nix-specific Calamares module configuration
    ---
    # Commands to prepare the Bloom Nix installation
    commands:
      # Commands to run before installation starts
      before:
        - command: "echo 'Preparing Bloom Nix installation...'"
        - command: "mkdir -p /mnt/etc/nixos"

      # Commands to run after installation completes
      after:
        - command: "nixos-generate-config --root /mnt"
        - command: "cp /etc/nixos/configuration.nix /mnt/etc/nixos/"
        - command: "echo 'Installing Bloom Nix...'"
        - command: "nixos-install --root /mnt"
  '';

  # Create a specialized installation script for Calamares to use
  environment.etc."calamares/scripts/bloom-install.sh".source =
    pkgs.writeScript "bloom-install.sh" ''
      #!/bin/sh
      # Bloom Nix installation script for Calamares

      set -e  # Exit on any error

      # Common variables
      TARGET="/mnt"
      BLOOM_CONFIG="$TARGET/etc/nixos/configuration.nix"

      # Function to log messages with timestamps
      log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
      }

      # Function to handle errors
      error() {
        log "ERROR: $1"
        exit 1
      }

      # Prepare the target system
      prepare_system() {
        log "Preparing target system directories..."
        mkdir -p $TARGET/etc/nixos || error "Failed to create Bloom Nix configuration directory"
      }

      # Generate the Bloom Nix configuration
      generate_config() {
        log "Generating Bloom Nix configuration..."
        nixos-generate-config --root $TARGET || error "Failed to generate base configuration"

        # Customize the configuration for Bloom Nix
        log "Customizing configuration for Bloom Nix..."
        sed -i 's/NixOS/Bloom Nix/g' $BLOOM_CONFIG

        # Add Bloom Nix branding
        sed -i '/^}/i \  # Bloom Nix branding\n  system.stateVersion = "23.11";\n' $BLOOM_CONFIG

        # Add selected packages to configuration.nix based on Calamares selections
        if [ -f "/tmp/selected_packages.txt" ]; then
          log "Adding selected packages to configuration..."
          PACKAGES=$(cat /tmp/selected_packages.txt)
          sed -i "/environment.systemPackages = with pkgs; \[/a\\    $PACKAGES" $BLOOM_CONFIG
        fi
      }

      # Install Bloom Nix to the target
      install_system() {
        log "Installing Bloom Nix to $TARGET..."
        nixos-install --root $TARGET || error "Failed to install Bloom Nix"
      }

      # Main installation process
      main() {
        log "Starting Bloom Nix installation..."

        prepare_system
        generate_config
        install_system

        log "Installation completed successfully!"
      }

      # Execute the main function
      main
    '';

  # Create a wrapper script to launch Calamares with proper environment variables
  environment.systemPackages = with pkgs; [
    # Wrapper script for starting Calamares reliably
    (writeScriptBin "start-calamares" ''
      #!/bin/sh

      # Set Qt environment variables to improve compatibility
      export QT_QPA_PLATFORMTHEME=qt5ct
      export QT_PLUGIN_PATH=${pkgs.qt5.qtbase}/lib/qt-${pkgs.qt5.qtbase.version}/plugins
      export QML2_IMPORT_PATH=${pkgs.qt5.qtquickcontrols2}/lib/qt-${pkgs.qt5.qtbase.version}/qml

      # Handle different display servers
      if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        export QT_QPA_PLATFORM=wayland
      else
        export QT_QPA_PLATFORM=xcb
      fi

      # Run Calamares with elevated privileges
      # First try with pkexec for a graphical password prompt
      if command -v pkexec >/dev/null 2>&1; then
        echo "Starting Calamares with pkexec..."
        pkexec ${pkgs.calamares}/bin/calamares
      else
        # Fall back to sudo if pkexec is not available
        echo "Starting Calamares with sudo..."
        sudo ${pkgs.calamares}/bin/calamares
      fi
    '')

    # Another script for debugging Calamares
    (writeScriptBin "calamares-debug" ''
      #!/bin/sh

      # Create a log file
      LOG_FILE="/tmp/calamares-debug-$(date '+%Y%m%d-%H%M%S').log"

      echo "Starting Calamares in debug mode..."
      echo "Log will be saved to $LOG_FILE"

      # Set environment variables for detailed logging
      export QT_LOGGING_RULES="*.debug=true"
      export CALAMARES_DEBUG=1

      # Run Calamares with elevated privileges and capture output
      sudo ${pkgs.calamares}/bin/calamares -d 2>&1 | tee $LOG_FILE
    '')
  ];

  # Add a proper desktop entry for the Calamares wrapper
  environment.etc."skel/Desktop/bloom-installer.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Bloom Nix
    GenericName=System Installer
    Comment=Install the Bloom Nix system to your computer
    Exec=start-calamares
    Icon=calamares
    Terminal=false
    StartupNotify=true
    Categories=Qt;System;
    Keywords=installer;calamares;system;
  '';
}
