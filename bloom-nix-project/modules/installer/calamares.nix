
# modules/installer/calamares.nix
# Enhanced Calamares configuration for Bloom Nix with KDE integration
{ config, lib, pkgs, ... }:

{
  # Ensure we have all required dependencies
  environment.systemPackages = with pkgs; [
    calamares-nixos
    
    # Qt dependencies - optimized for KDE integration
    libsForQt5.full
    libsForQt5.kpmcore
    libsForQt5.kiconthemes
    qt5.qttools
    qt5.qtquickcontrols2
    qt5.qtsvg
    
    # Filesystem tools
    parted gptfdisk e2fsprogs dosfstools ntfs3g
    btrfs-progs xfsprogs f2fs-tools
    
    # Python and support libraries
    python3
    python3Packages.pyqt5
    python3Packages.pyyaml
    
    # Additional tools for better experience
    os-prober
    gptfdisk
    cryptsetup
  ];
  
  # Ensure KDE theme is set for Calamares
  programs.dconf.enable = true;
  
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
        
        # KDE integration
        qmlSearch:            [".", "/etc/calamares/qml"]
        widgetStyle:          "Breeze"
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
    
    # Create more user-friendly default partitioning
    defaultFileSystemType:  "ext4"
    
    # Available file system types
    availableFileSystemTypes:
        - ext4
        - btrfs
        - xfs
        - vfat
        - ntfs
  '';
  
  # Improved module configuration for a better user experience
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
        - packages
        - displaymanager
        - grubcfg
        - bootloader-config
        - bootloader
        - umount
      - show:
        - finished
        
    branding: bloom-nix
    
    prompt-install: true
    
    dont-chroot: false
    
    # KDE-specific settings
    style:
      qmlSearchPaths: ["/etc/calamares/qml"]
      styleSheet: "/etc/calamares/branding/bloom-nix/stylesheet.qss"
      palette:
        button: ${config.plasma-theme.colors.background}
  '';
  
  # Add an improved user module configuration for better defaults
  environment.etc."calamares/modules/users.conf".text = ''
    ---
    # Better user creation configuration
    defaultGroups:
        - users
        - wheel
        - video
        - audio
        - network
        - storage
        - disk
    
    # Allow users to reuse passwords
    passwordMatchCheck: true
    
    # Allow auto-login
    allowWeakPasswords: false
    allowWeakPasswordsDefault: false
    
    # Set default hostname
    defaultUserName: user
    defaultHostName: bloom-nix
    
    # Show user password strength
    showPasswordStrength: true
    
    # Automatically login after install
    doAutoLogin: true
  '';
  
  # Create a better startup experience for Calamares
  environment.etc."xdg/autostart/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Bloom Nix
    GenericName=System Installer
    Comment=Install the operating system to your computer
    Exec=calamares
    Icon=calamares
    Terminal=false
    StartupNotify=true
    Categories=Qt;System;
    X-AppStream-Ignore=true
  '';
  
  # Add a helper script to run Calamares with debug output
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "calamares-debug" ''
      #!/bin/sh
      mkdir -p ~/.config/calamares
      ln -sf /etc/calamares/* ~/.config/calamares/ || true
      calamares -d
    '')
    
    # Add a welcome application to enhance first-time experience
    (writeShellScriptBin "bloom-welcome" ''
      #!/bin/sh
      # Simple welcome script
      if [ -f /run/live-media ]; then
        # We're in live mode
        kdialog --title "Welcome to Bloom Nix" \
          --yesnocancel "Welcome to Bloom Nix!\n\nWould you like to install Bloom Nix to your computer?" \
          --yes-label "Install Now" \
          --no-label "Explore First"
          
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
          # Yes - install
          calamares
        elif [ $RESULT -eq 1 ]; then
          # No - explore
          dolphin &
        fi
      fi
    '')
  ];
  
  # Auto-start welcome screen in live environment
  environment.etc."xdg/autostart/bloom-welcome.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Welcome to Bloom Nix
    Comment=Welcome screen for Bloom Nix
    Exec=/run/current-system/sw/bin/bloom-welcome
    Terminal=false
    X-KDE-autostart-phase=1
    OnlyShowIn=KDE;
  '';
}
