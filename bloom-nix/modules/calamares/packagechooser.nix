# modules/calamares/packagechooser.nix
# This module configures the packagechooser module in Calamares
{ config, lib, pkgs, ... }:

{
  # Package choices configuration for Calamares
  environment.etc."calamares/modules/packagechooser.conf".text = ''
    # Configuration file for Calamares packagechooser module
    ---
    # Package selection mode - options are "optional" or "required"
    # With "required", the user must select exactly one option
    # With "optional", the user can select any number (including none)
    mode: "optional"

    # This controls how the packages are displayed
    method: "custom"

    # Show the "Software Selection" page
    # If this is false, the software selection page will be skipped
    required: true

    # The title of the page
    title: "Bloom Nix Software Selection"

    # A brief description of what this page does
    introduction: "Choose the software categories you would like to install."

    # Should the selection be expanded by default?
    expanded: true

    # Default selected packages (by id)
    default: [ "base" ]

    # Package groups for selection
    # Each item defines a package selection group
    items:
      - id: "base"
        name: "Base System"
        description: "Basic system tools and utilities"
        screenshot: "/etc/calamares/images/base.png"
        selected: true
        # This selection can't be deselected, as it's the base system
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
        description: "Programming tools and development environments"
        screenshot: "/etc/calamares/images/dev.png"
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
        description: "Gaming platforms and tools"
        screenshot: "/etc/calamares/images/gaming.png"
        packages:
          - steam
          - lutris
          - wine
          - discord
          - gamemode
          - mangohud

      - id: "multimedia"
        name: "Multimedia Production"
        description: "Audio, video, and image editing tools"
        screenshot: "/etc/calamares/images/multimedia.png"
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
        description: "Office suites and productivity tools"
        screenshot: "/etc/calamares/images/office.png"
        packages:
          - libreoffice
          - thunderbird
          - gnome-calendar
          - zotero
          - obsidian

      - id: "science"
        name: "Science & Education"
        description: "Scientific and educational software"
        screenshot: "/etc/calamares/images/science.png"
        packages:
          - rstudio
          - octave
          - gnuplot
          - celestia
          - stellarium
          - geogebra
          - anki
  '';

  # Add the packagechooser module to the Calamares execution sequence
  environment.etc."calamares/modules/exec.conf".text = lib.mkAfter ''
    # Add packagechooser to the execution sequence before packages
    - id: packagechooser
      module: packagechooser
      config: /etc/calamares/modules/packagechooser.conf
  '';
}
