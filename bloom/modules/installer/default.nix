# Calamares installer configuration for Bloom Nix
{ config, lib, pkgs, ... }:

let
  # Import brand colors
  bloomColors = config._module.args.bloomColors or {
    primary = "#FF5F15";    # Orange primary color
    secondary = "#3C0061";  # Purple secondary color
  };
  
  # Create a custom Calamares configuration package
  customCalamares = pkgs.calamares.overrideAttrs (old: {
    # We would build against Qt6 if possible
    # cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_PREFIX_PATH=${pkgs.qt6.qtbase.dev}" ];
  });
  
  # Create a custom Calamares branding package
  calamaresBloomBranding = pkgs.stdenvNoCC.mkDerivation {
    name = "calamares-bloom-branding";
    
    # No source needed, we'll create files during build
    dontUnpack = true;
    
    # Install configuration files
    installPhase = ''
      mkdir -p $out/share/calamares/branding/bloom
      
      # Install branding configuration
      cat > $out/share/calamares/branding/bloom/branding.desc << EOF
      ---
      componentName: bloom
      welcomeStyleCalamares: true
      welcomeExpandingLogo: true
      
      # Colors
      slideshowAPI: 1
      style:
        sidebarBackground: "${bloomColors.secondary}"
        sidebarText: "#FFFFFF"
        sidebarTextSelect: "${bloomColors.primary}"
      
      # Images
      productLogo: "bloom-logo.png"
      productIcon: "bloom-icon.png"
      productWelcome: "welcome.png"
      
      # Slideshow
      slideshow: "show.qml"
      
      # Strings
      strings:
          productName:         "Bloom Nix"
          shortProductName:    "Bloom"
          version:             "1.0"
          shortVersion:        "1.0"
          versionedName:       "Bloom Nix 1.0"
          shortVersionedName:  "Bloom 1.0"
          bootloaderEntryName: "Bloom Nix"
          productUrl:          "https://bloom-nix.org/"
      EOF
      
      # Copy branding assets
      cp -r ${../branding/assets}/calamares/* $out/share/calamares/branding/bloom/
      
      # Create QML slideshow
      cat > $out/share/calamares/branding/bloom/show.qml << EOF
      import QtQuick 2.5;
      import calamares.slideshow 1.0;
      
      Presentation {
          id: presentation
          
          Timer {
              interval: 20000
              running: true
              repeat: true
              onTriggered: presentation.goToNextSlide()
          }
          
          Slide {
              Image {
                  id: slide1
                  source: "slides/slide1.png"
                  fillMode: Image.PreserveAspectFit
                  anchors.centerIn: parent
              }
          }
          
          Slide {
              Image {
                  id: slide2
                  source: "slides/slide2.png"
                  fillMode: Image.PreserveAspectFit
                  anchors.centerIn: parent
              }
          }
          
          Slide {
              Image {
                  id: slide3
                  source: "slides/slide3.png"
                  fillMode: Image.PreserveAspectFit
                  anchors.centerIn: parent
              }
          }
      }
      EOF
    '';
  };
  
  # Custom module for package selection
  packageSelectorModule = pkgs.writeTextFile {
    name = "packageSelector.conf";
    text = ''
      ---
      # Package selection module configuration
      
      # Module metadata
      name: packageSelector
      id: packageSelector
      weight: 50
      requiredModules: [ machineid, locale, keyboard ]
      
      # Configuration
      mode: required
      
      # Package groups
      packageGroups:
        - id: gaming
          name: "Gaming"
          description: "Gaming packages including Steam, Lutris, Wine, and game optimization tools."
          packages:
            - steam
            - lutris
            - wine
            - gamemode
            - mangohud
            
        - id: development
          name: "Software Development"
          description: "Tools for software development including IDEs, compilers, and version control."
          packages:
            - vscode
            - git
            - gcc
            - python3
            - nodejs
            
        - id: office
          name: "Office & Productivity"
          description: "Office applications for document editing, spreadsheets, and presentations."
          packages:
            - libreoffice
            - thunderbird
            - onlyoffice-desktopeditors
            
        - id: multimedia
          name: "Multimedia"
          description: "Applications for creating and consuming media content."
          packages:
            - gimp
            - inkscape
            - blender
            - kdenlive
            - audacity
            
        - id: science
          name: "Scientific Computing"
          description: "Tools for scientific research, data analysis, and mathematics."
          packages:
            - rstudio
            - octave
            - python3Packages.numpy
            - python3Packages.scipy
            - python3Packages.matplotlib
    '';
    destination = "/share/calamares/modules/packageSelector.conf";
  };
  
  # Create a settings package for Calamares
  calamaresSettings = pkgs.stdenvNoCC.mkDerivation {
    name = "calamares-settings-bloom";
    
    # No source needed, we'll create files during build
    dontUnpack = true;
    
    # Install configuration files
    installPhase = ''
      mkdir -p $out/share/calamares
      
      # Main settings file
      cat > $out/share/calamares/settings.conf << EOF
      ---
      # Modules configuration
      modules-search: [ local, /run/current-system/sw/share/calamares/modules ]
      
      # Sequence of modules to execute
      sequence:
        - show:
            - welcome
            - locale
            - keyboard
            - partition
            - users
            - packageSelector
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
            - bootloader
            - umount
        - show:
            - finished
      
      # Instance-specific settings
      branding: bloom
      prompt-install: true
      dont-chroot: false
      disable-cancel: false
      disable-cancel-during-exec: true
      EOF
      
      # Copy the custom package selector module
      cp ${packageSelectorModule} $out/share/calamares/modules/
      
      # Create a launcher script
      mkdir -p $out/bin
      cat > $out/bin/bloom-installer << EOF
      #!/bin/sh
      # Launch Calamares with our custom settings
      exec calamares -D8 -d -c /run/current-system/sw/share/calamares/settings.conf
      EOF
      chmod +x $out/bin/bloom-installer
    '';
  };
in
{
  # Add Calamares to the system
  environment.systemPackages = with pkgs; [
    # The main Calamares installer
    calamares
    
    # Our custom configurations
    calamaresBloomBranding
    calamaresSettings
    
    # Tools needed for the installer
    e2fsprogs
    dosfstools
    ntfs3g
    gptfdisk
    parted
  ];
  
  # Make the installer automatically appear on the desktop
  environment.etc."skel/Desktop/installer.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Bloom Nix
    Comment=Install the operating system to your computer
    Exec=${calamaresSettings}/bin/bloom-installer
    Icon=calamares
    Terminal=false
    Categories=System;
  '';
  
  # Make the installed system preserve our customizations
  system.activationScripts.installerCustomization = ''
    # Create a custom hook for Calamares to run post-installation
    mkdir -p /etc/calamares/scripts
    cat > /etc/calamares/scripts/bloom-post-install.sh << 'EOF'
    #!/bin/sh
    # This script runs after installation to configure the installed system
    
    # Apply the same desktop settings as the live environment
    if [ -d /etc/skel/.config ]; then
      cp -r /etc/skel/.config /home/$USER/
      chown -R $USER:$USER /home/$USER/.config
    fi
    
    # Enable the same services
    systemctl enable NetworkManager
    systemctl enable sddm
    
    # Set the installed system hostname
    echo "bloom-nix" > /etc/hostname
    
    # Configure Plymouth theme
    plymouth-set-default-theme bloom-nix
    
    # Rebuild the initramfs to include plymouth theme
    dracut --force
    
    exit 0
    EOF
    chmod +x /etc/calamares/scripts/bloom-post-install.sh
  '';
}
