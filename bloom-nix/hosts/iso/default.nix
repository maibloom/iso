# modules/calamares/default.nix
# This module configures Calamares installer for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Import all Calamares module configurations
  imports = [
    ./packagechooser.nix
  ];

  # Install Calamares
  environment.systemPackages = with pkgs; [
    pkgs.calamares
    # These dependencies are needed for Calamares to function properly
    parted
    gptfdisk
    cryptsetup
    dmidecode
  ];

  # Basic Calamares configuration
  environment.etc = {
    # Main Calamares settings
    "calamares/settings.conf".text = ''
      # Configuration file for Calamares
      # Execution sequence for Bloom Nix installer
      ---
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
            - packages
            - grubcfg
            - bootloader
            - umount
        - show:
            - finished

      # Branding settings
      branding: bloom
      
      # Prompt when quitting
      prompt-install: true
      
      # Don't show "Cancel" button
      dont-chroot: false
      
      # Allow canceling the installation
      disable-cancel: false
      
      # Allow quitting the installer
      disable-cancel-during-exec: false
      quit-at-end: false
    '';

    # Welcome module configuration
    "calamares/modules/welcome.conf".text = ''
      # Welcome module configuration for Calamares
      ---
      showSupportUrl:         true
      showKnownIssuesUrl:     true
      showReleaseNotesUrl:    true
      
      # Requirements checking
      requireStorage:         true
      requireMemory:          true
      requireInternet:        false
      requireSwap:            false
      
      # Set minimum values
      requiredStorage:        20
      requiredRam:            2.0
      
      # URLs
      supportUrl:             "https://github.com/yourusername/bloom-nix/issues"
      knownIssuesUrl:         "https://github.com/yourusername/bloom-nix/issues"
      releaseNotesUrl:        "https://github.com/yourusername/bloom-nix/releases"
      
      # Check for internet connection
      internetCheckUrl:       "https://1.1.1.1"
    '';

    # Users module configuration
    "calamares/modules/users.conf".text = ''
      # Users module configuration for Calamares
      ---
      # Default username to be shown
      defaultUserName:                "user"
      
      # Default full name
      defaultFullName:                "Bloom Nix User"
      
      # Default password for the user
      defaultPassword:                ""
      
      # Default hostname
      defaultHostName:                "bloom-nix"
      
      # What login shells to offer
      loginShells:
        - name: "Bash"
          command: "/bin/bash"
          shortcut: "b"
        - name: "Zsh"
          command: "/bin/zsh"
          shortcut: "z"
      
      # Default shell to use
      defaultLoginShell:              "/bin/bash"
      
      # Require password strength
      requireStrongPasswords:         true
      
      # Auto-login user
      doAutoLogin:                    true
      
      # Set root password the same as user password
      setRootPassword:                false
      
      # Allow to select the root account name independently
      allowRootUser:                  false
      
      # Password checking
      passwordStrengthWarningLevel:   50
      
      # Allow non-ASCII names
      allowWeakPasswords:             false
      
      # Only show username and hostname fields (for preconfigured setups)
      allowWeakPasswordsDefault:      false
    '';

    # Packages module configuration (works with packagechooser)
    "calamares/modules/packages.conf".text = ''
      # Packages module configuration for Calamares
      ---
      # Manage system packages during installation
      # Update the system, install/remove packages
      #
      # The field 'operations' is a list of operations to perform
      # during installation:
      # - the install target package
      # - the remove target package
      # - the try_install target package (if possible, not critical)
      # - the try_remove target package (if possible, not critical)
      # 
      # Each operation can have an empty list of packages, in which case
      # nothing is done for that operation.
      operations:
        - install:
            - sudo
            - networkmanager
            - plasma-desktop
            - firefox
            - konsole
            - dolphin
            - kate
        - remove:
            - calamares-framework
      
      # Package manager to use - for NixOS we don't really use this directly,
      # but need to specify something for Calamares to be happy
      backend: apt
      
      # Skip the installation if the system doesn't need it
      skip_if_no_internet: false
      
      # Don't update the package database
      update_db: false
      
      # Don't update system packages
      update_system: false
    '';

    # Unpackfs module configuration 
    "calamares/modules/unpackfs.conf".text = ''
      # Unpackfs module configuration for Calamares
      ---
      # Unpack the rootfs to the destination
      unpack:
        -   source: "/run/media/nix-store"
            sourcefs: "squashfs"
            destination: ""
    '';

    # Create branding directory
    "calamares/branding/bloom/branding.desc".text = ''
      ---
      componentName:   bloom
      welcomeStyleCalamares: true
      welcomeExpandingLogo: true
      
      strings:
          productName:         Bloom NixOS
          shortProductName:    Bloom Nix
          version:             1.0.0
          shortVersion:        1.0
          versionedName:       Bloom NixOS 1.0.0
          shortVersionedName:  Bloom 1.0
          bootloaderEntryName: Bloom NixOS
          productUrl:          https://github.com/yourusername/bloom-nix
          supportUrl:          https://github.com/yourusername/bloom-nix/issues
          
      images:
          productLogo:         "logo.png"
          productIcon:         "logo.png"
          productWelcome:      "welcome.png"
          
      slideshow:               "show.qml"
      
      style:
          sidebarBackground:   "#2D2D2D"
          sidebarText:         "#FFFFFF"
          sidebarTextSelect:   "#FFFFFF"
          sidebarTextHighlight: "#74C0E3"
    '';

    # Create a simple slideshow for the installer
    "calamares/branding/bloom/show.qml".text = ''
      /* Slideshow QML file for Calamares */
      
      import QtQuick 2.0;
      import calamares.slideshow 1.0;
      
      Presentation
      {
          id: presentation
          
          Timer {
              interval: 20000
              running: true
              repeat: true
              onTriggered: presentation.goToNextSlide()
          }
          
          Slide {
              Image {
                  id: background1
                  source: "slide1.png"
                  anchors.centerIn: parent
                  width: parent.width
                  height: parent.height
                  horizontalAlignment: Image.AlignCenter
                  verticalAlignment: Image.AlignCenter
                  
                  Text {
                      anchors.centerIn: parent
                      text: "Welcome to Bloom NixOS"
                      color: "white"
                      font.pixelSize: 32
                      font.bold: true
                  }
              }
          }
          
          Slide {
              Image {
                  id: background2
                  source: "slide2.png"
                  anchors.centerIn: parent
                  width: parent.width
                  height: parent.height
                  horizontalAlignment: Image.AlignCenter
                  verticalAlignment: Image.AlignCenter
                  
                  Text {
                      anchors.centerIn: parent
                      text: "Reproducible and Declarative System Configuration"
                      color: "white"
                      font.pixelSize: 32
                      font.bold: true
                  }
              }
          }
          
          Slide {
              Image {
                  id: background3
                  source: "slide3.png"
                  anchors.centerIn: parent
                  width: parent.width
                  height: parent.height
                  horizontalAlignment: Image.AlignCenter
                  verticalAlignment: Image.AlignCenter
                  
                  Text {
                      anchors.centerIn: parent
                      text: "Rolling Updates and Atomic Upgrades"
                      color: "white"
                      font.pixelSize: 32
                      font.bold: true
                  }
              }
          }
      }
    '';
  };

  # Create necessary directories and symlinks
  system.activationScripts.calamaresSetup = ''
    mkdir -p /etc/calamares/branding/bloom
    mkdir -p /etc/calamares/images
    mkdir -p /etc/calamares/modules
    
    # Create symlinks for branding assets if they don't exist yet
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/branding/bloom/logo.png
    ln -sf ${../../modules/branding/assets/grub-background.png} /etc/calamares/branding/bloom/slide1.png
    ln -sf ${../../modules/branding/assets/grub-background.png} /etc/calamares/branding/bloom/slide2.png
    ln -sf ${../../modules/branding/assets/grub-background.png} /etc/calamares/branding/bloom/slide3.png
    ln -sf ${../../modules/branding/assets/grub-background.png} /etc/calamares/branding/bloom/welcome.png
    
    # Create symlinks for package selection category images
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/images/base.png
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/images/dev.png
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/images/gaming.png
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/images/multimedia.png
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/images/office.png
    ln -sf ${../../modules/branding/assets/logo.png} /etc/calamares/images/science.png
  '';
}
