# modules/installer/calamares-config.nix
{ config, lib, pkgs, ... }:

{
  environment.etc = {
    # Main Calamares configuration file - adding our custom shellprocess modules
    "calamares/settings.conf".text = ''
      modules-search: [ local, /run/current-system/sw/lib/calamares/modules ]
      
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
            - networkcfg
            - machineid
            - fstab
            - locale
            - keyboard
            - localecfg
            - users
            - displaymanager
            - packagechooser
            - shellprocess@copy-bloom-nix    # Copy Bloom Nix modules
            - shellprocess@setup-flake        # Create flake.nix
            - shellprocess@hardware-config    # Generate hardware configuration
            - grubcfg
            - bootloader
            - shellprocess@install-flake      # Install using the flake
            - umount
        - show:
            - finished
      
      branding: bloom-nix
      prompt-install: true
      dont-chroot: true
    '';
    
    # Welcome module configuration
    "calamares/modules/welcome.conf".text = ''
      showSupportUrl:         false
      showKnownIssuesUrl:     false
      showReleaseNotesUrl:    false
      requireStorage:         true
      requireMemory:          0.5
      requiredStorage:        5.0
      internetCheckUrl:       https://networkcheck.kde.org
    '';
    
    # Users module configuration
    "calamares/modules/users.conf".text = ''
      defaultGroups:
          - video
          - wheel
          - networkmanager
      autologinGroup: autologin
      doAutologin: true
      sudoersGroup: wheel
      passwordRequirements:
          nonempty: true
          minLength: 1
          maxLength: -1
      allowWeakPasswords: true
      allowWeakPasswordsDefault: true
    '';

    # Custom shellprocess to copy Bloom Nix modules to target system
    "calamares/modules/shellprocess-copy-bloom-nix.conf".text = ''
      name: "Copying Bloom Nix modules..."
      script:
        - "mkdir -p /tmp/bloom-nix-installer"
        - "mkdir -p /mnt/etc/nixos/modules/base"
        - "mkdir -p /mnt/etc/nixos/modules/hardware"
        - "mkdir -p /mnt/etc/nixos/modules/desktop"
        - "mkdir -p /mnt/etc/nixos/modules/packages"
        - "cp -r /run/current-system/etc/bloom-nix-modules/* /mnt/etc/nixos/modules/"
        - "chmod -R u+w /mnt/etc/nixos"
    '';

    # Custom shellprocess to create flake.nix in the installed system
    "calamares/modules/shellprocess-setup-flake.conf".text = ''
      name: "Creating flake.nix configuration..."
      script:
        - cp -f /run/current-system/etc/bloom-nix-installer/flake-template.nix /mnt/etc/nixos/flake.nix
        - sed -i "s/@HOSTNAME@/$HOSTNAME/g" /mnt/etc/nixos/flake.nix
        - sed -i "s/@USERNAME@/$USER/g" /mnt/etc/nixos/flake.nix
        - sed -i "s/@PASSWORD_HASH@/$USER_PASSWORD_HASH/g" /mnt/etc/nixos/flake.nix
        - touch /mnt/etc/nixos/.git
    '';

    # Custom shellprocess to generate hardware configuration
    "calamares/modules/shellprocess-hardware-config.conf".text = ''
      name: "Generating hardware configuration..."
      script:
        - nixos-generate-config --root /mnt --no-filesystems
    '';

    # Custom shellprocess to install the system using flakes
    "calamares/modules/shellprocess-install-flake.conf".text = ''
      name: "Installing system using flakes..."
      script:
        - cd /mnt/etc/nixos
        - nixos-install --no-root-passwd --flake ".#system"
    '';
    
    # Create the Bloom Nix branding
    "calamares/branding/bloom-nix/branding.desc".text = ''
      ---
      componentName:  bloom-nix
      
      strings:
          productName:         Bloom Nix
          shortProductName:    Bloom Nix
          version:             1.0
          shortVersion:        1.0
          versionedName:       Bloom Nix 1.0
          shortVersionedName:  Bloom Nix 1.0
          bootloaderEntryName: Bloom Nix
          productUrl:          https://github.com/yourusername/bloom-nix
      
      images:
          productLogo:         "bloom-logo.png"
          productIcon:         "bloom-logo.png"
          productWelcome:      "welcome.png"
      
      style:
          sidebarBackground:   "#282c34"
          sidebarText:         "#FFFFFF"
          sidebarTextSelect:   "#FFFFFF"
          sidebarTextHighlight: "#5294E2"
    '';

    # Create flake template for the installed system
    "bloom-nix-installer/flake-template.nix".text = ''
      {
        description = "Bloom Nix System Configuration";
      
        inputs = {
          # Core Nix inputs
          nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
          nixos-hardware.url = "github:NixOS/nixos-hardware";
      
          # Home Manager for user configurations
          home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
          };
        };
      
        outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
          {
            # System configuration
            nixosConfigurations.system = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                # Include hardware configuration generated by nixos-generate-config
                ./hardware-configuration.nix
                
                # Include home-manager
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                }
                
                # Bloom Nix base configuration
                ./modules/base/default.nix
                ./modules/hardware/default.nix
                ./modules/desktop/plasma6.nix
                ./modules/packages/default.nix
                
                # Host-specific configuration
                {
                  # Set hostname
                  networking.hostName = "@HOSTNAME@";
                  
                  # Create user account
                  users.users.@USERNAME@ = {
                    isNormalUser = true;
                    extraGroups = [ "wheel" "networkmanager" "video" ];
                    hashedPassword = "@PASSWORD_HASH@";
                  };
                  
                  # Set system state version
                  system.stateVersion = "23.05";
                }
              ];
            };
          };
      }
    '';
  };

  # Create a simple logo and welcome image for the branding
  system.activationScripts.calamaresSetup = ''
    # Create directories for branding and installer files
    mkdir -p /run/current-system/sw/share/calamares/branding/bloom-nix
    mkdir -p /run/current-system/etc/bloom-nix-modules
    
    # Copy Bloom Nix modules for the installer to use
    cp -r ${./..}/base /run/current-system/etc/bloom-nix-modules/
    cp -r ${./..}/hardware /run/current-system/etc/bloom-nix-modules/
    cp -r ${./..}/desktop /run/current-system/etc/bloom-nix-modules/
    cp -r ${./..}/packages /run/current-system/etc/bloom-nix-modules/
    
    # Create a simple placeholder logo if it doesn't exist
    if [ ! -f /run/current-system/sw/share/calamares/branding/bloom-nix/bloom-logo.png ]; then
      ${pkgs.imagemagick}/bin/convert -size 128x128 canvas:transparent -fill "#5294E2" -draw "circle 64,64 64,0" -font Helvetica -pointsize 64 -gravity center -annotate 0 "B" /run/current-system/sw/share/calamares/branding/bloom-nix/bloom-logo.png
    fi
    
    # Create a simple placeholder welcome image if it doesn't exist
    if [ ! -f /run/current-system/sw/share/calamares/branding/bloom-nix/welcome.png ]; then
      ${pkgs.imagemagick}/bin/convert -size 640x480 gradient:#282c34-#5294E2 -font Helvetica -pointsize 36 -gravity center -annotate 0 "Welcome to Bloom Nix" /run/current-system/sw/share/calamares/branding/bloom-nix/welcome.png
    fi
  '';
}
