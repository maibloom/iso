# Enhanced Calamares configuration for Bloom Nix with KDE integration
{ config, lib, pkgs, ... }:

let
  # Brand colors - should match your branding module
  colors = {
    primary = "#454d6e";
    secondary = "#f1efee";
    accent = "#999a5e";
    neutral = "#989cad";
    highlight = "#ab6470";
    darkPrimary = "#353d5e";
  };
  
  # Direct references to branding directory files
  brandingDir = ../../branding;
  
  # Create the Calamares branding directory structure
  calamaresTheme = pkgs.runCommand "calamares-theme-bloom-nix" {} ''
    mkdir -p $out/etc/calamares/branding/bloom-nix
    
    # Copy branding images directly from the branding directory
    cp ${brandingDir}/logo.png $out/etc/calamares/branding/bloom-nix/
    cp ${brandingDir}/bloom-logo.png $out/etc/calamares/branding/bloom-nix/icon.png
    cp ${brandingDir}/welcome.png $out/etc/calamares/branding/bloom-nix/ || cp ${brandingDir}/splash.png $out/etc/calamares/branding/bloom-nix/welcome.png
    cp ${brandingDir}/background.png $out/etc/calamares/branding/bloom-nix/wallpaper.png || cp ${brandingDir}/default.jpg $out/etc/calamares/branding/bloom-nix/wallpaper.png
    
    # Copy slideshow images if they exist
    mkdir -p $out/etc/calamares/branding/bloom-nix/slides
    cp ${brandingDir}/slide1.png $out/etc/calamares/branding/bloom-nix/slides/ || true
    cp ${brandingDir}/slide2.png $out/etc/calamares/branding/bloom-nix/slides/ || true
    
    # Create simple slideshow.qml if it doesn't exist
    cat > $out/etc/calamares/branding/bloom-nix/slideshow.qml << EOF
import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQml 2.2

Item {
    id: presentation
    width: 800
    height: 450

    property int animationDuration: 1000
    property int slideDuration: 10000
    property int numSlides: 2
    property int currentSlide: 0

    Timer {
        id: advanceTimer
        interval: slideDuration
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function goToNextSlide() {
        currentSlide = (currentSlide + 1) % numSlides
    }

    Repeater {
        model: numSlides
        
        Image {
            id: slide
            source: "slides/slide" + (index + 1) + ".png"
            width: presentation.width
            height: presentation.height
            fillMode: Image.PreserveAspectFit
            opacity: presentation.currentSlide === index ? 1.0 : 0.0
            Behavior on opacity { PropertyAnimation { duration: presentation.animationDuration } }
        }
    }
}
EOF

    # Create a simple stylesheet.qss
    cat > $out/etc/calamares/branding/bloom-nix/stylesheet.qss << EOF
QWidget {
    font-family: "Noto Sans";
}

QToolBar {
    background-color: ${colors.primary};
    color: ${colors.secondary};
}

QPushButton {
    background-color: ${colors.primary};
    color: ${colors.secondary};
    border: 1px solid ${colors.highlight};
    border-radius: 3px;
    padding: 6px 12px;
}

QPushButton:hover {
    background-color: ${colors.highlight};
}

QLabel {
    color: ${colors.primary};
}

#sidebarApp {
    background-color: ${colors.primary};
}

#sidebarMenuApp {
    background-color: ${colors.primary};
    color: ${colors.secondary};
}
EOF
  '';
in {
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
 
  # Add the Calamares theme to the system
  system.extraDependencies = [ calamaresTheme ];
  
  # Create symlinks to make sure Calamares finds the branding files
  system.activationScripts.calamaresTheme = {
    text = ''
      # Create required directories
      mkdir -p /etc/calamares/branding/bloom-nix
      mkdir -p /etc/calamares/modules
      mkdir -p /etc/calamares/qml
      
      # Use our prepared branding directory
      if [ -d ${calamaresTheme}/etc/calamares/branding/bloom-nix ]; then
        cp -rf ${calamaresTheme}/etc/calamares/branding/bloom-nix/* /etc/calamares/branding/bloom-nix/
      fi
      
      # Make sure the branding is readable
      chmod -R +r /etc/calamares
    '';
    deps = [];
  };
 
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
        # Using absolute paths to ensure the installer finds the images
        productLogo:         "/etc/calamares/branding/bloom-nix/logo.png"
        productIcon:         "/etc/calamares/branding/bloom-nix/icon.png"
        productWelcome:      "/etc/calamares/branding/bloom-nix/welcome.png"
        productWallpaper:    "/etc/calamares/branding/bloom-nix/wallpaper.png"
    
    slideshow:               "slideshow.qml"
    
    style:
        sidebarBackground:   "${colors.primary}"
        sidebarText:         "${colors.secondary}"
        sidebarTextHighlight: "${colors.highlight}"
        
        # KDE integration
        qmlSearch:           [".", "/etc/calamares/qml", "/etc/calamares/branding/bloom-nix"]
        widgetStyle:         "Breeze"
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
      qmlSearchPaths: ["/etc/calamares/qml", "/etc/calamares/branding/bloom-nix"]
      styleSheet: "/etc/calamares/branding/bloom-nix/stylesheet.qss"
      palette:
        button: "${colors.primary}"
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
