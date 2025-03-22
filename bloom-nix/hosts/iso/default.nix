# ISO-specific configuration for Bloom Nix - Using custom Plasma 6
{ config, pkgs, lib, inputs, outputs, ... }:

{
  # ISO-specific configuration
  isoImage = {
    # Set ISO filename and volume ID
    isoName = lib.mkForce "bloom-nix.iso";
    volumeID = lib.mkForce "BLOOM_NIX";

    # Make the ISO bootable via both BIOS and UEFI
    makeEfiBootable = true;
    makeUsbBootable = true;

    # Add build information to the ISO label
    appendToMenuLabel = " Live";
    squashfsCompression = "gzip";
  };

  # Live environment user configuration
  users.users.nixos = {
    isNormalUser = true;
    description = "Bloom Nix Live User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    # No password for live environment
    initialPassword = "";
  };

  # Allow sudo without password for live environment
  security.sudo.wheelNeedsPassword = false;

  # Desktop shortcuts - create these in the appropriate location
  environment.etc = {
    "skel/Desktop/install.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Install Bloom Nix
      Comment=Install the operating system to your computer
      Exec=calamares
      Icon=calamares
      Terminal=false
      Categories=System;
    '';
    
    "skel/Desktop/terminal.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Terminal
      Comment=Access the command line
      Exec=${lib.getBin pkgs.kdePackages.konsole}/bin/konsole
      Icon=utilities-terminal
      Terminal=false
      Categories=System;
    '';
  };

  # Add the Bloom installer to the system
  environment.systemPackages = with pkgs; [
    calamares-framework
    # Add any other ISO-specific packages here
    gparted
    parted
    ntfs3g
    dosfstools
    
    # Additional tools that might be useful in the live environment
    wget
    curl
    git
    htop
  ];

  # Automatically log in the live user to the Wayland session
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Configure Bloom branding in the SDDM login screen
  services.displayManager.sddm.settings = {
    Theme = {
      Current = "breeze";
      CursorTheme = "breeze_cursors";
      Font = "Noto Sans,10,-1,50,0,0,0,0,0,0,0";
    };
    Users = {
      MaximumUid = 60000;
      MinimumUid = 1000;
    };
    General = {
      DisplayServer = "wayland";
      InputMethod = "";
    };
  };

  # Ensure the desktop gets our custom configurations
  services.xserver.desktopManager.plasma6 = {
    enable = true;
  };

  # Make sure that file manager has enhanced functionality
  programs.kdeconnect.enable = true;
}
