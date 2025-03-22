# ISO-specific configuration for Bloom Nix
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
    squashfsCompression = "zstd";  # Better compression algorithm
    
    # Fix the image name properly with mkForce to override defaults
    edition = lib.mkForce "kde";
  };
  
  # Set the base name for the image (using the correct option path)
  image.baseName = lib.mkForce "bloom-nix";

  # Live environment user configuration - using bloomnix as the username
  users.users.bloomnix = {
    isNormalUser = true;
    description = "Bloom Nix Live User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "scanner" "lp" ];
    # No password required for login
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
    
    "skel/Desktop/file-manager.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=File Manager
      Comment=Browse your files
      Exec=${lib.getBin pkgs.kdePackages.dolphin}/bin/dolphin
      Icon=system-file-manager
      Terminal=false
      Categories=System;
    '';
    
    "issue".text = ''
      \e[1;35mBloom Nix\e[0m Live ISO
      \l
    '';
    
    "issue.net".text = ''
      Bloom Nix Live ISO
    '';
  };

  # Add the Bloom installer and essential tools to the system
  environment.systemPackages = with pkgs; [
    # Installation tools
    calamares-framework
    gparted
    parted
    ntfs3g
    dosfstools
    
    # Network tools
    networkmanager
    networkmanagerapplet
    
    # System utilities
    pciutils
    usbutils
    lshw
    dmidecode
    
    # Archive management
    zip
    unzip
    p7zip
    
    # Multimedia codecs and support
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  # Automatically log in the live user
  services.displayManager.autoLogin = {
    enable = true;
    user = "bloomnix";
  };
  
  # Enhanced boot configuration for the ISO
  boot = {
    kernelModules = [ "loop" "overlay" "squashfs" ];
    
    # Show Bloom Nix splash during boot
    plymouth = {
      enable = true;
      theme = "breeze";
    };
    
    # Increase console resolution during boot
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "i915.modeset=1" 
      "amdgpu.modeset=1"
      "nvidia-drm.modeset=1"
    ];
  };
  
  # ISO-specific fixes and tweaks
  environment.variables = {
    # Ensure Wayland works well on the ISO
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };
  
  # Custom ISO branding
  services.xserver.displayManager.sddm.settings = {
    Theme.Current = "breeze";
    Theme.CursorTheme = "breeze_cursors";
    Theme.Font = "Noto Sans,10,-1,50,0,0,0,0,0,0,0";
  };
  
  # Enable live media specific services
  services.openssh.permitRootLogin = "no";
  services.getty.autologinUser = "bloomnix";
  
  # Ensure certain services are enabled in the live environment
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  
  # Preserve space by removing unnecessary files
  environment.noXlibs = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;
  programs.command-not-found.enable = false;
}
