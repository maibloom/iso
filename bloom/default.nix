{ system ? builtins.currentSystem,
  nixpkgs ? <nixpkgs>,  # Uses the system's nixpkgs channel
  modulesDir ? ./modules # Directory containing your custom modules
}:

let
  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  lib = pkgs.lib;
 
  # Generate a graphical NixOS ISO with Plasma 6 and the bash installer
  nixos = import "${nixpkgs}/nixos" {
    configuration = { config, lib, pkgs, modulesPath, ... }: {
      imports = [
        # Use the graphical installation image base
        "${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"
       
        # Import your additional modules
        "${modulesDir}/base.nix"
        "${modulesDir}/branding.nix"
        "${modulesDir}/hardware-base.nix"
        "${modulesDir}/plasma.nix"
      ];
     
      # Override renamed options from hardware-base.nix
      services.libinput = {
        enable = lib.mkForce true;
        touchpad = lib.mkForce {
          tapping = true;
          naturalScrolling = true;
          disableWhileTyping = true;
        };
      };
     
      # New path for OpenGL configuration
      hardware.graphics.enable = lib.mkForce true;
     
      # Desktop and display managers configuration - fixed to work with Plasma 6
      services.desktopManager = {
        plasma6.enable = true;  # Enable Plasma 6
      };
      services.displayManager = {
        sddm.enable = true;
        defaultSession = "plasma";
      };
     
      # Add KDE applications and tools (no Calamares)
      environment.systemPackages = with pkgs; [
        # Tools needed by the bash installer
        parted
        gparted
        e2fsprogs
        dosfstools
        util-linux
        
        # Core KDE packages
        kdePackages.plasma-desktop
        kdePackages.plasma-workspace
        kdePackages.plasma-nm
        kdePackages.dolphin
        kdePackages.konsole
        kdePackages.kate
        kdePackages.ark
        kdePackages.plasma-systemmonitor
        
        # Additional useful tools
        firefox
        gparted
        git
        wget
        curl
      ];
      
      # Copy the installer script to the system and make it executable
      system.activationScripts.installBloomScript = {
        text = ''
          mkdir -p /usr/local/bin
          cp ${modulesDir}/install-bloom.sh /usr/local/bin/
          chmod +x /usr/local/bin/install-bloom.sh
        '';
        deps = [];
      };
     
      # Create desktop entry for the installer
      environment.etc."xdg/autostart/bloom-installer.desktop" = {
        text = ''
          [Desktop Entry]
          Name=Install Bloom NixOS
          GenericName=System Installer
          Comment=Install Bloom NixOS on your computer
          Exec=sudo /usr/local/bin/install-bloom.sh
          Icon=system-software-install
          Terminal=true
          Type=Application
          Categories=System;
        '';
        mode = "0644";
      };
      
      # Create desktop icon for manual launch
      environment.etc."usr/share/applications/bloom-installer.desktop" = {
        text = ''
          [Desktop Entry]
          Name=Install Bloom NixOS
          GenericName=System Installer
          Comment=Install Bloom NixOS on your computer
          Exec=sudo /usr/local/bin/install-bloom.sh
          Icon=system-software-install
          Terminal=true
          Type=Application
          Categories=System;
        '';
        mode = "0644";
      };
      
      # Configure polkit to allow launching the installer without password
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id === "org.freedesktop.policykit.exec" &&
              action.lookup("program") === "/usr/local/bin/install-bloom.sh" &&
              subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
      
      # Copy modules to a standard location for the installer to find
      system.activationScripts.copyModules = {
        text = ''
          # Create necessary directories
          mkdir -p /etc/nixos/bloom-modules
          
          # Copy modules
          cp -r ${modulesDir}/* /etc/nixos/bloom-modules/
        '';
        deps = ["installBloomScript"];
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
     
      # Custom welcome message
      services.getty.helpLine = ''
        Welcome to Bloom Nix with Plasma 6!
       
        Log in as "nixos" user to start the graphical environment.
        The password is empty.
       
        The installer will launch automatically after login.
        You can also run it manually with: sudo /usr/local/bin/install-bloom.sh
      '';
    };
  };
in {
  # The ISO image
  iso = nixos.config.system.build.isoImage;
 
  # Expose the full NixOS evaluation for debugging
  inherit nixos;
}
