{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bloom-installer;
in {
  options.services.bloom-installer = {
    enable = mkEnableOption "Bloom Nix text-based installer";
    
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
    # Core dependencies for the installer - using proper NixOS packages
    environment.systemPackages = with pkgs; [
      dialog                # For the TUI interface
      parted                # For disk partitioning
      gptfdisk              # For GPT partition tables
      utillinux             # For various utilities
      e2fsprogs             # For formatting ext4 filesystems
      dosfstools            # For formatting FAT filesystems
      coreutils             # Basic utilities
      procps                # Process utilities
      mkpasswd              # For password hashing
      ncurses               # For better terminal support
      lsof                  # For process inspection
      nixos-install-tools   # NixOS installation utilities
      rsync                 # For copying files
      git                   # For managing configurations
      kdePackages.konsole   # Terminal for launching installer
    ];

    # Generate a script to copy project files
    environment.etc."bloom-installer/copy-project-files.sh" = {
      text = ''
        #!/bin/sh
        # Script to copy Bloom Nix project files to the installed system
        set -e
        
        TARGET_DIR="$1"
        if [ -z "$TARGET_DIR" ]; then
          echo "Error: Target directory not specified"
          exit 1
        fi
        
        # Create directory structure
        mkdir -p "$TARGET_DIR/modules"
        mkdir -p "$TARGET_DIR/hosts/desktop"
        
        # Copy module directories
        echo "Copying base modules..."
        cp -r ${cfg.modulePaths.base} "$TARGET_DIR/modules/base"
        
        echo "Copying desktop modules..."
        cp -r ${cfg.modulePaths.desktop} "$TARGET_DIR/modules/desktop"
        
        echo "Copying hardware modules..."
        cp -r ${cfg.modulePaths.hardware} "$TARGET_DIR/modules/hardware"
        
        echo "Copying package modules..."
        cp -r ${cfg.modulePaths.packages} "$TARGET_DIR/modules/packages"
        
        echo "Copying branding modules and assets..."
        cp -r ${cfg.modulePaths.branding} "$TARGET_DIR/modules/branding"
        
        # Copy host configurations
        echo "Copying host configuration..."
        cp -r ${cfg.installedSystem.hostConfig}/* "$TARGET_DIR/hosts/desktop/"
        
        # Create core flake.nix if it doesn't exist
        if [ ! -f "$TARGET_DIR/flake.nix" ]; then
          echo "Creating flake.nix..."
          cat > "$TARGET_DIR/flake.nix" << EOF
        {
          description = "Bloom Nix System Configuration";
        
          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
            home-manager = {
              url = "github:nix-community/home-manager";
              inputs.nixpkgs.follows = "nixpkgs";
            };
          };
        
          outputs = { self, nixpkgs, home-manager, ... }@inputs:
          {
            nixosConfigurations = {
              bloom = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                  ./hosts/desktop
                  home-manager.nixosModules.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                  }
                ];
              };
            };
          };
        }
        EOF
        fi
        
        echo "Project files successfully copied to $TARGET_DIR"
      '';
      mode = "0755";
    };
    
    # Install the main installer script
    environment.etc."bloom-installer/bloom-installer.sh" = {
      source = ./bloom-installer.sh;
      mode = "0755";
    };
    
    # Create a wrapper script that passes project information to the installer
    environment.etc."bloom-installer/run-installer.sh" = {
      text = ''
        #!/bin/sh
        # Wrapper script that provides project information to the installer
        
        # Set environment variables with project paths
        export BLOOM_PROJECT_ROOT="${cfg.projectRoot}"
        export BLOOM_MODULE_BASE="${cfg.modulePaths.base}"
        export BLOOM_MODULE_DESKTOP="${cfg.modulePaths.desktop}"
        export BLOOM_MODULE_HARDWARE="${cfg.modulePaths.hardware}"
        export BLOOM_MODULE_PACKAGES="${cfg.modulePaths.packages}"
        export BLOOM_MODULE_BRANDING="${cfg.modulePaths.branding}"
        export BLOOM_HOST_CONFIG="${cfg.installedSystem.hostConfig}"
        export BLOOM_ENABLE_PLASMA6="${toString cfg.installedSystem.enablePlasma6}"
        
        # Run the actual installer
        exec /etc/bloom-installer/bloom-installer.sh
      '';
      mode = "0755";
    };

    # Create desktop file for launching the installer
    environment.etc."xdg/autostart/bloom-installer.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Install Bloom Nix
        GenericName=System Installer
        Comment=Install Bloom Nix to your computer
        Exec=${pkgs.kdePackages.konsole}/bin/konsole -e sudo /etc/bloom-installer/run-installer.sh
        Icon=system-software-install
        Terminal=false
        StartupNotify=true
        Categories=System;
      '';
      mode = "0644";
    };

    # Add a desktop shortcut
    systemd.services.bloom-installer-setup = {
      description = "Setup for Bloom Nix Installer";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "bloom-installer-setup" ''
          # Create desktop icon
          mkdir -p /home/nixos/Desktop
          cat > /home/nixos/Desktop/bloom-installer.desktop << EOF
          [Desktop Entry]
          Type=Application
          Name=Install Bloom Nix
          GenericName=System Installer
          Comment=Install Bloom Nix to your computer
          Exec=${pkgs.kdePackages.konsole}/bin/konsole -e sudo /etc/bloom-installer/run-installer.sh
          Icon=system-software-install
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

    # Allow password-less sudo for running the installer
    security.sudo.extraConfig = ''
      # Allow live user to run the installer without a password
      nixos ALL=(ALL) NOPASSWD: /etc/bloom-installer/bloom-installer.sh
      nixos ALL=(ALL) NOPASSWD: /etc/bloom-installer/run-installer.sh
      nixos ALL=(ALL) NOPASSWD: /etc/bloom-installer/copy-project-files.sh
    '';

    # Create welcome notification that launches the installer
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
            --icon=system-software-install \
            --urgency=normal \
            "Welcome to Bloom Nix!" \
            "Click here to start the installation process." \
            --action=default="Install Now" \
            --hint=string:desktop-entry:bloom-installer
          
          # If notification is clicked, launch installer
          if [ $? -eq 0 ]; then
            ${pkgs.kdePackages.konsole}/bin/konsole -e sudo /etc/bloom-installer/run-installer.sh &
          fi
        '';
      };
    };

    # Open a terminal with the installer on first login
    systemd.user.services.bloom-installer-autostart = {
      description = "Auto-start Bloom Nix Installer";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "autostart-installer" ''
          # Check if this is the first boot
          if [ ! -f "$HOME/.bloom-installer-seen" ]; then
            # Mark that we've run this once
            touch "$HOME/.bloom-installer-seen"
            
            # Launch installer in a terminal
            ${pkgs.kdePackages.konsole}/bin/konsole -e sudo /etc/bloom-installer/run-installer.sh &
          fi
        '';
      };
    };
    
    # Also configure a TTY login to automatically start the installer
    # This provides a fallback if the graphical environment fails
    environment.loginShellInit = ''
      # Auto-start installer on TTY if it's the first login
      if [[ "$(tty)" == "/dev/tty1" ]] && [[ ! -f "$HOME/.bloom-installer-tty-seen" ]]; then
        touch "$HOME/.bloom-installer-tty-seen"
        clear
        echo "Starting Bloom Nix Installer..."
        sudo /etc/bloom-installer/run-installer.sh
      fi
    '';

    # Adding a prompt to the user's bashrc to remind them about the installer
    environment.interactiveShellInit = ''
      if [[ -z "$DISPLAY" && "$(tty)" != "/dev/tty1" ]]; then
        echo ""
        echo -e "\033[1;35mWelcome to Bloom Nix!\033[0m"
        echo -e "\033[0;36mTo start the installer, run: \033[1;36msudo /etc/bloom-installer/run-installer.sh\033[0m"
        echo ""
      fi
    '';
  };
}
