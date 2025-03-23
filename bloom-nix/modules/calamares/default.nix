# modules/calamares/default.nix
# This module configures Calamares installer for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Import all Calamares module configurations
  imports = [
    ./packagechooser.nix
    ./nix-installer-support.nix
  ];

  # Install Calamares and its dependencies
  environment.systemPackages = with pkgs; [
    # Main Calamares package
    calamares

    # Qt dependencies that Calamares needs
    libsForQt5.full  # Comprehensive Qt5 libraries
    libsForQt5.kpmcore
    libsForQt5.kparts
    libsForQt5.kservice
    libsForQt5.ki18n

    # System tools needed for partitioning and system configuration
    parted
    gptfdisk
    cryptsetup
    dmidecode
    rsync

    # Other necessary utilities
    pkgs.python3Full
    bash
    util-linux  # For fdisk, mount, etc.
    e2fsprogs   # For mkfs.ext4
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
            - calamares

      # Package manager to use - we set "dummy" for Nix-based systems since we'll handle
      # packages through the configuration.nix generation
      backend: dummy

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
          productName:         Bloom Nix
          shortProductName:    Bloom Nix
          version:             1.0.0
          shortVersion:        1.0
          versionedName:       Bloom Nix 1.0.0
          shortVersionedName:  Bloom Nix 1.0
          bootloaderEntryName: Bloom Nix
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
                      text: "Welcome to Bloom Nix"
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
  # Using a more robust approach to symlink creation
  system.activationScripts.calamaresSetup = ''
    # Create required directories
    mkdir -p /etc/calamares/branding/bloom
    mkdir -p /etc/calamares/images
    mkdir -p /etc/calamares/modules

    # Helper function to safely create symlinks
    create_symlink() {
      source="$1"
      target="$2"
      if [ -e "$source" ]; then
        ln -sf "$source" "$target"
      else
        echo "Warning: Source file '$source' does not exist, cannot create symlink"
      fi
    }

    # Create symlinks for branding assets
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/branding/bloom/logo.png"
    create_symlink "${../../modules/branding/assets/grub-background.png}" "/etc/calamares/branding/bloom/slide1.png"
    create_symlink "${../../modules/branding/assets/grub-background.png}" "/etc/calamares/branding/bloom/slide2.png"
    create_symlink "${../../modules/branding/assets/grub-background.png}" "/etc/calamares/branding/bloom/slide3.png"
    create_symlink "${../../modules/branding/assets/grub-background.png}" "/etc/calamares/branding/bloom/welcome.png"

    # Create symlinks for package selection category images
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/images/base.png"
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/images/dev.png"
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/images/gaming.png"
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/images/multimedia.png"
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/images/office.png"
    create_symlink "${../../modules/branding/assets/logo.png}" "/etc/calamares/images/science.png"

    # Set proper permissions for Calamares to run with sudo
    if [ -f /etc/sudoers.d/calamares ]; then
      echo "Updating Calamares sudo permissions..."
    else
      echo "Creating Calamares sudo permissions..."
      echo "nixos ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/calamares" > /etc/sudoers.d/calamares
      chmod 440 /etc/sudoers.d/calamares
    fi
  '';

  # Configure polkit to allow Calamares to run with elevated privileges
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "com.github.calamares.calamares.pkexec.run" ||
           action.id == "org.freedesktop.policykit.exec" ||
           action.id.indexOf("org.freedesktop.udisks2.") == 0) &&
          subject.local && subject.active && subject.isInGroup("wheel")) {
            return polkit.Result.YES;
      }
    });
  '';
}
