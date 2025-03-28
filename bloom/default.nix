{ system ? builtins.currentSystem,
  nixpkgs ? <nixpkgs>  # Uses the system's nixpkgs channel
}:

let
  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  lib = pkgs.lib;
 
  # Generate a graphical NixOS ISO with Plasma 6 and manually configured Calamares
  nixos = import "${nixpkgs}/nixos" {
    configuration = { config, lib, pkgs, modulesPath, ... }: {
      imports = [
        # Use the graphical installation image that is available in your channel
        "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
        
        # If needed, you can alternatively try one of these (uncomment one at a time):
        # "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix"
        # "${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"
        
        # Import your additional modules
        ./modules/base.nix
        ./modules/branding.nix
        ./modules/hardware-base.nix
        ./modules/plasma.nix
        # ./modules/installer.nix  # (optional; may be redundant)
      ];
      
      # Use the new option names for the desktop and display managers:
      services.desktopManager = {
        plasma5.enable = lib.mkForce false;  # Disable Plasma 5
        plasma6.enable = true;               # Enable Plasma 6
      };
      services.displayManager = {
        sddm.enable = true;
        defaultSession = "plasma";
      };
      
      # Add Calamares and additional KDE applications and tools.
      # Replace the old top-level plasma-desktop alias with the explicit package from kdePackages.
      environment.systemPackages = with pkgs; [
        calamares
        calamares-nixos-extensions
        ckbcomp  # For keyboard configuration
        kdePackages.plasma-desktop
        plasma-workspace
        plasma-nm
        dolphin
        konsole
        kate
        ark
        plasma-systemmonitor
        gparted
      ];
      
      # Create desktop entry for Calamares
      environment.etc."xdg/autostart/calamares-installer.desktop" = {
        text = ''
          [Desktop Entry]
          Name=Install Bloom Nix
          GenericName=System Installer
          Comment=Install the Bloom Nix operating system to your computer
          Exec=pkexec calamares
          Icon=calamares
          Terminal=false
          StartupNotify=true
          Type=Application
          Categories=Qt;System;
        '';
        mode = "0644";
      };
      
      # Customize Calamares branding
      environment.etc."calamares/branding/bloom/branding.desc" = {
        text = ''
          # Bloom Nix Branding for Calamares
          ---
          componentName: bloom
          
          # These strings are displayed during installation
          strings:
            productName:         Bloom Nix
            shortProductName:    Bloom
            version:             ${config.system.nixos.label}
            shortVersion:        ${config.system.nixos.label}
            versionedName:       Bloom Nix ${config.system.nixos.label}
            shortVersionedName:  Bloom ${config.system.nixos.label}
            bootloaderEntryName: Bloom Nix
            productUrl:          https://nixos.org
          
          # Colors for text and background
          style:
            sidebarBackground:   "#2D2D2D"
            sidebarText:         "#EFEFEF"
            sidebarTextCurrent:  "#81C1E4"
        '';
        mode = "0644";
      };
      
      # Basic Calamares configuration
      environment.etc."calamares/settings.conf" = {
        text = ''
          # Configuration file for Calamares
          # Adjusted for Bloom Nix with Plasma 6
          
          # Modules to use in the installation process
          modules-search: [ local, /etc/calamares/modules ]
          
          # Sequence of installation steps
          sequence:
            - show:
                - welcome
                - locale
                - keyboard
                - partition
                - users
                - summary
            - exec:
                - partition
                - mount
                - unpackfs
                - machineid
                - fstab
                - locale
                - keyboard
                - localecfg
                - users
                - displaymanager
                - networkcfg
                - packages
                - grubcfg
                - bootloader
                - umount
            - show:
                - finished
          
          # Branding configuration
          branding: bloom
          
          # User interface configuration
          prompt-install: true
        '';
        mode = "0644";
      };
      
      # Customize ISO branding for Bloom Nix
      isoImage = {
        isoName = "bloom-nix-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
        volumeID = "BLOOM_NIX";
        makeEfiBootable = true;
        makeUsbBootable = true;
        appendToMenuLabel = " Bloom Nix";
      };
      
      # Set distribution name
      system.nixos.distroName = "Bloom Nix";
      system.nixos.distroId = "bloom";
      
      # Ensure user has proper permissions
      users.users.nixos.extraGroups = [ "wheel" "networkmanager" ];
      
      # Create a custom /etc/issue for console login
      services.getty.helpLine = ''
        Welcome to Bloom Nix with Plasma 6 and Calamares!
        
        Log in as "nixos" user to start the graphical environment.
        The password is empty.
        
        To start the installation, launch Calamares from the desktop.
      '';
      
      # Ensure the Calamares folders exist for our branding
      system.activationScripts.calamaresFolders = {
        text = ''
          mkdir -p /etc/calamares/modules
          mkdir -p /etc/calamares/branding/bloom
        '';
        deps = [];
      };
      
      # Additional polkit rules to allow Calamares to run with pkexec
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id === "org.freedesktop.policykit.exec" &&
              action.lookup("program") === "/run/current-system/sw/bin/calamares" &&
              subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
  };
in {
  # The ISO image
  iso = nixos.config.system.build.isoImage;
  
  # Expose the full NixOS evaluation for debugging
  inherit nixos;
}
