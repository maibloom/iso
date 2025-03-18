# modules/installer/calamares.nix
# Enhanced Calamares configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Enable the Calamares installer
  services.xserver.displayManager.sddm.enable = true;
  
  # Ensure we have all required dependencies
  environment.systemPackages = with pkgs; [
    calamares-nixos
    
    # Qt dependencies
    libsForQt5.full
    libsForQt5.kpmcore
    qt5.qttools
    qt5.qtquickcontrols2
    
    # Filesystem tools
    parted
    gptfdisk
    e2fsprogs
    dosfstools
    ntfs3g
    
    # Python dependencies
    python3
    python3Packages.pyqt5
    python3Packages.pyyaml
  ];
  
  # Ensure the installer has proper branding
  environment.etc."calamares/branding/bloom-nix/branding.desc".text = ''
    ---
    componentName:  bloom-nix
    
    strings:
        productName:         Bloom Nix
        shortProductName:    Bloom Nix
        version:             1.0.0
        shortVersion:        1.0
        versionedName:       Bloom Nix 1.0
        shortVersionedName:  Bloom Nix 1.0
        bootloaderEntryName: Bloom Nix
        productUrl:          https://github.com/yourusername/bloom-nix
        supportUrl:          https://github.com/yourusername/bloom-nix/issues
        knownIssuesUrl:      https://github.com/yourusername/bloom-nix/wiki/Known-Issues
        releaseNotesUrl:     https://github.com/yourusername/bloom-nix/wiki/Release-Notes
    
    images:
        productLogo:         "logo.png"
        productIcon:         "icon.png"
        productWelcome:      "welcome.png"
        productWallpaper:    "wallpaper.png"
    
    slideshow:               "slideshow.qml"
    
    style:
        sidebarBackground:    "#454d6e"
        sidebarText:          "#FFFFFF"
        sidebarTextHighlight: "#5e96fe"
  '';
  
  # Make sure Calamares knows what partitioning tools to use
  environment.etc."calamares/modules/partition.conf".text = ''
    ---
    efiSystemPartition:     "/boot/efi"
    userSwapChoices:        true
    
    # Default partitioning scheme
    defaultPartitionTableType: gpt
    
    # Names of additional packages to be installed with Bloom Nix
    initialPackages:
        - calamares
        - grub
        - os-prober
        - ntfs-3g
  '';
  
  # Set up proper module loading
  environment.etc."calamares/settings.conf".text = ''
    ---
    modules-search: [ local, /etc/calamares/modules ]
    
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
        - networkcfg
        - hwclock
        - services-systemd
        - bootloader-config
        - bootloader
        - umount
      - show:
        - finished
        
    branding: bloom-nix
    
    prompt-install: true
    
    dont-chroot: false
  '';
  
  # Create a startup script to fix potential issues with Calamares
  environment.etc."xdg/autostart/calamares-debug.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Calamares Debug Helper
    Comment=Fixes Calamares configuration issues on boot
    Exec=/usr/bin/env bash -c 'sleep 5; mkdir -p ~/.config/calamares; ln -sf /etc/calamares/* ~/.config/calamares/ || true'
    Terminal=false
    Hidden=false
  '';
  
  # Add a helper script to run Calamares with debug output
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "calamares-debug" ''
      #!/bin/sh
      mkdir -p ~/.config/calamares
      ln -sf /etc/calamares/* ~/.config/calamares/ || true
      calamares -d
    '')
  ];
}
