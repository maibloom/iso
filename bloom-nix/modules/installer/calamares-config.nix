{ config, lib, pkgs, ... }:

{
  environment.etc = {
    # Main Calamares configuration file – adding our custom shellprocess modules
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
  };

  # Make Calamares available in the system and create a desktop entry for it
  environment.systemPackages = with pkgs; [
    calamares-nixos
  ];
  
  environment.etc."xdg/autostart/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Bloom Nix
    GenericName=System Installer
    Comment=Calamares — System Installer for Bloom Nix
    Exec=pkexec calamares
    Icon=calamares
    Terminal=false
    StartupNotify=true
    Categories=Qt;System;
  '';
}
