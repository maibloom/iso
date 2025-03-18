# config/configuration.nix
{ config, pkgs, lib, ... }:

{
  # allowing unfree apps, so users would be able to download and install apps like vscode and drivers.
  nixpkgs.config.allowUnfree = true;
  
  imports = [ 
    ./hardware-configuration.nix
    ../modules/branding
    ../modules/desktop/xfce.nix
    ../modules/installer/calamares.nix
  ];

  # Modern boot configuration with renamed options
  boot.loader = {
    timeout = lib.mkForce 5;  # Fixed option name
    grub = {
      enable = lib.mkForce true;
      efiSupport = lib.mkDefault true;
      device = lib.mkDefault "nodev";
      useOSProber = true;
      timeoutStyle = "hidden";
      # timeout is now at boot.loader.timeout
      theme = ../branding/grub/theme;
      backgroundColor = "#454d6e";
      extraConfig = ''
        set default=0
        set timeout_style=hidden
      '';
    };
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  # Networking configuration
  networking.hostName = "bloom-nix";
  networking.networkmanager.enable = true;
  time.timeZone = "UTC";
 
  # System packages
  environment.systemPackages = with pkgs; [
    vim wget git libgcc rustup brave
    ungoogled-chromium
    # Additional KDE packages
    libsForQt5.packagekit-qt
    libsForQt5.qt5.qtgraphicaleffects
    kdePackages.dolphin
  ];

  # Enable sound with PipeWire (better for KDE)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.openssh.enable = true;
 
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    initialPassword = "password";
  };

  # Set the system name
  system.nixos.distroName = "Bloom Nix";


  # Kernel parameters for boot splash
  boot.kernelParams = [ "quiet" "splash" "vga=current" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" ];

  system.stateVersion = "23.11";
}
