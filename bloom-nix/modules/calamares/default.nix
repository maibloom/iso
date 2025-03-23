# modules/calamares/default.nix
# Calamares configuration that doesn't require external image files
{ config, lib, pkgs, ... }:

{
  # Install Calamares and essential dependencies
  environment.systemPackages = with pkgs; [
    # The installer itself
    calamares

    # Essential dependencies
    parted
    gptfdisk
    cryptsetup
    e2fsprogs
    dosfstools
    ntfs3g

    # Create a simple launcher script for Calamares
    (writeScriptBin "launch-installer" ''
      #!/bin/sh
      # Simple launcher for Calamares with proper privileges

      # Try pkexec first (graphical sudo)
      if command -v pkexec >/dev/null 2>&1; then
        pkexec ${pkgs.calamares}/bin/calamares
      else
        # Fall back to sudo
        sudo ${pkgs.calamares}/bin/calamares
      fi
    '')

    # Debug launcher for troubleshooting
    (writeScriptBin "debug-installer" ''
      #!/bin/sh
      # Debug launcher for Calamares with logging
      LOG_FILE="/tmp/calamares-debug-$(date '+%Y%m%d-%H%M%S').log"
      echo "Starting Calamares in debug mode..."
      echo "Log will be saved to $LOG_FILE"

      export QT_LOGGING_RULES="*.debug=true"
      sudo ${pkgs.calamares}/bin/calamares -d 2>&1 | tee $LOG_FILE
    '')
  ];

  # Ensure the live user can run Calamares with sudo without a password
  security.sudo.extraRules = [{
    users = [ "nixos" ];
    commands = [{
      command = "${pkgs.calamares}/bin/calamares";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Add a desktop shortcut for the installer
  environment.etc."skel/Desktop/install.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Bloom Nix
    Comment=Install Bloom Nix to your computer
    Exec=launch-installer
    Icon=calamares
    Terminal=false
    Categories=System;
  '';

  # Add a desktop shortcut for the debug launcher
  environment.etc."skel/Desktop/debug-installer.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Debug Installer
    Comment=Launch installer in debug mode
    Exec=debug-installer
    Icon=utilities-terminal
    Terminal=true
    Categories=System;Development;
  '';

  # Create a simple autostart entry
  environment.etc."xdg/autostart/bloom-installer.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bloom Nix Installer
    Comment=Install Bloom Nix to your computer
    Exec=launch-installer
    Icon=calamares
    Terminal=false
    StartupNotify=true
  '';

  # Allow Calamares to run with elevated privileges through polkit
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.policykit.exec" ||
           action.id == "com.github.calamares.calamares.pkexec.run" ||
           action.id.indexOf("org.freedesktop.udisks2.") == 0) &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # PACKAGE SELECTION CONFIGURATION
  # ==============================

  # Package selection module configuration - No images required
  environment.etc."calamares/modules/packagechooser.conf".text = ''
    # Configuration for Calamares packagechooser module
    ---
    # Package selection mode - options are "optional" or "required"
    # With "optional", the user can select any number of packages
    mode: "optional"

    # Method for displaying packages - using "process" instead of "custom"
    # to avoid requiring screenshots
    method: "process"

    # Show the package selection page
    required: true

    # Title and introduction text
    title: "Bloom Nix Software Selection"
    introduction: "Choose the software categories you would like to install."

    # Should the selection be expanded by default?
    expanded: true

    # Default selected packages (by id)
    default: [ "base" ]

    # Package groups for selection - no screenshot URLs
    items:
      - id: "base"
        name: "Base System"
        description: "Basic system tools and utilities (Firefox, git, vim, etc.)"
        selected: true
        immutable: true
        packages:
          - firefox
          - git
          - vim
          - wget
          - curl
          - htop
          - neofetch

      - id: "dev"
        name: "Development"
        description: "Programming tools and development environments (VS Code, gcc, Python, etc.)"
        packages:
          - vscode
          - gcc
          - rustup
          - python3
          - nodejs
          - cmake
          - jupyter

      - id: "gaming"
        name: "Gaming"
        description: "Gaming platforms and tools (Steam, Lutris, Wine, etc.)"
        packages:
          - steam
          - lutris
          - wine
          - discord
          - gamemode
          - mangohud

      - id: "multimedia"
        name: "Multimedia Production"
        description: "Audio, video, and image editing tools (GIMP, Blender, OBS, etc.)"
        packages:
          - kdenlive
          - gimp
          - blender
          - audacity
          - obs-studio
          - inkscape
          - krita

      - id: "office"
        name: "Office & Productivity"
        description: "Office suites and productivity tools (LibreOffice, Thunderbird, etc.)"
        packages:
          - libreoffice
          - thunderbird
          - gnome-calendar
          - zotero
          - obsidian

      - id: "science"
        name: "Science & Education"
        description: "Scientific and educational software (RStudio, Octave, etc.)"
        packages:
          - rstudio
          - octave
          - gnuplot
          - celestia
          - stellarium
          - geogebra
          - anki
  '';

  # Add the packagechooser module to the sequence
  environment.etc."calamares/settings.conf".text = ''
    # Calamares Settings
    ---
    # Sequence defines the order of modules
    sequence:
      - show:
          - welcome
          - locale
          - keyboard
          - packagechooser  # Package selection added here
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
          - hwclock
          - packages
          - grubcfg
          - bootloader
          - umount
      - show:
          - finished

    # Branding
    branding: bloom

    # Prompt when quitting
    prompt-install: true

    # Allow canceling
    disable-cancel: false
    disable-cancel-during-exec: true
    quit-at-end: false
  '';

  # Configure packages module to work with packagechooser
  environment.etc."calamares/modules/packages.conf".text = ''
    # Packages module configuration
    ---
    # We use dummy backend for package operations in a Nix-based system
    # This is because we'll handle package installation through configuration.nix
    backend: dummy

    # Basic operations - these will be modified at install time
    # based on the packagechooser selections
    operations:
      - install:
          - sudo
          - networkmanager
          - plasma-desktop
      - remove:
          - calamares

    # Do not update the system during installation
    update_system: false
  '';

  # BRANDING CONFIGURATION WITHOUT IMAGE DEPENDENCIES
  # =====================

  # Create branding directory and description
  environment.etc."calamares/branding/bloom/branding.desc".text = ''
    ---
    componentName: bloom

    # Strings used in the GUI
    strings:
        productName:         Bloom Nix
        shortProductName:    Bloom Nix
        version:             1.0.0
        shortVersion:        1.0
        versionedName:       Bloom Nix 1.0.0
        shortVersionedName:  Bloom 1.0
        bootloaderEntryName: Bloom Nix

    # Slideshow
    slideshow:               "show.qml"

    # Style
    style:
        sidebarBackground:   "#2D2D2D"
        sidebarText:         "#FFFFFF"
        sidebarTextSelect:   "#FFFFFF"
        sidebarTextHighlight: "#74C0E3"
  '';

  # Create QML slideshow that doesn't require external images
  environment.etc."calamares/branding/bloom/show.qml".text = ''
    /* Slideshow QML file for Calamares that doesn't require external images */

    import QtQuick 2.0;
    import calamares.slideshow 1.0;

    Presentation {
        id: presentation

        Timer {
            interval: 15000
            running: true
            repeat: true
            onTriggered: presentation.goToNextSlide()
        }

        Slide {
            Rectangle {
                anchors.fill: parent
                color: "#1a365d"  // Dark blue background

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    spacing: 20

                    Text {
                        width: parent.width
                        text: "Welcome to Bloom Nix"
                        color: "white"
                        font.pixelSize: 32
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "A modern, declarative NixOS-based distribution"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Slide {
            Rectangle {
                anchors.fill: parent
                color: "#4a7729"  // Green background

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    spacing: 20

                    Text {
                        width: parent.width
                        text: "Reproducible System Configuration"
                        color: "white"
                        font.pixelSize: 32
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "Declare your entire system configuration in code for consistent, reproducible deployments"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Slide {
            Rectangle {
                anchors.fill: parent
                color: "#7c2855"  // Purple background

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    spacing: 20

                    Text {
                        width: parent.width
                        text: "Atomic Updates and Rollbacks"
                        color: "white"
                        font.pixelSize: 32
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "Safely update your system with the ability to roll back instantly if anything goes wrong"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Slide {
            Rectangle {
                anchors.fill: parent
                color: "#cc5500"  // Orange background

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    spacing: 20

                    Text {
                        width: parent.width
                        text: "Choose Your Software"
                        color: "white"
                        font.pixelSize: 32
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: "Select from various software categories to customize your Bloom Nix experience"
                        color: "white"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
  '';

  # Create script to save selected packages
  environment.etc."calamares/scripts/save-packages.sh".source =
    pkgs.writeScript "save-packages.sh" ''
      #!/bin/sh
      # Save selected packages from packagechooser to be used during installation

      # This script will be called by Calamares after package selection
      # It saves the selected packages to a file that can be read during the actual installation

      # Get selected packages from Calamares temporary config
      if [ -f "/tmp/calamares-packagechooser-selected.conf" ]; then
        cat "/tmp/calamares-packagechooser-selected.conf" > /tmp/selected_packages.txt
        echo "Selected packages saved to /tmp/selected_packages.txt"
      else
        echo "No package selections found"
      fi
    '';
}
