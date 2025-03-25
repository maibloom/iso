# XFCE desktop environment configuration for Bloom Nix
{ config, lib, pkgs, ... }:

let
  defaultUser = "nixos";
in {
  # Enable X server
  services.xserver.enable = true;
  
  # Enable XFCE desktop environment
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.lightdm = {
    enable = true;
    background = "#1a1a1a";
    # Ensure GTK+ theme is honored in greeter
    greeters.gtk = {
      enable = true;
      theme.name = "Materia-dark";
      iconTheme.name = "Papirus-Dark";
      extraConfig = ''
        hide-user-image=true
        position = 50%,center 50%,center
        font-name = Noto Sans 11
      '';
    };
  };
  
  # Enable auto-login for the live system
  services.xserver.displayManager.autoLogin = {
    enable = lib.mkDefault true;
    user = lib.mkDefault defaultUser;
  };

  # Install essential packages for XFCE
  environment.systemPackages = with pkgs; [
    # XFCE core and plugins
    xfce.xfce4-whiskermenu-plugin  # Modern menu
    xfce.xfce4-pulseaudio-plugin   # Volume control
    xfce.xfce4-weather-plugin      # Weather
    xfce.xfce4-battery-plugin      # Battery monitor
    xfce.xfce4-clipman-plugin      # Clipboard manager
    xfce.xfce4-cpugraph-plugin     # CPU monitor
    xfce.xfce4-systemload-plugin   # System load
    xfce.xfce4-netload-plugin      # Network monitor
    xfce.xfce4-places-plugin       # Quick access to folders
    
    # Themes and icons for a modern look
    arc-theme
    materia-theme
    papirus-icon-theme
    
    # Fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    
    # Useful applications
    firefox
    thunderbird
    vlc
    tilix  # Modern terminal
    pluma  # Simple text editor
    gnome.file-roller  # Archive manager
    gparted  # Partition editor
    xfce.ristretto  # Image viewer
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    
    # System utilities
    networkmanagerapplet
    pavucontrol  # Audio control
    udiskie       # Automount USB drives
    brightnessctl # Brightness control
    
    # Additional tools
    polkit_gnome
    gnome.gnome-disk-utility
    gnome.gnome-system-monitor
    xfce.xfce4-screenshooter  # Screenshot tool
    
    # VM support packages
    spice-vdagent
    xorg.xf86videoqxl
  ];
  
  # Enable important services
  services.gvfs.enable = true;  # Trash, mounts, etc.
  services.tumbler.enable = true;  # Thumbnails
  services.upower.enable = true;  # Power management
  services.acpid.enable = true;  # ACPI events (e.g. lid close)
  services.printing.enable = true;  # Printing
  services.blueman.enable = true;  # Bluetooth
  
  # Setup automount for removable devices
  services.devmon.enable = true;
  services.udisks2.enable = true;
  
  # Audio configuration - Correctly configured to avoid conflicts
  # Remove sound.enable as it's deprecated
  # Ensure PulseAudio is disabled if you're using PipeWire elsewhere
  hardware.pulseaudio.enable = false;  # Disable PulseAudio to avoid conflicts with PipeWire
  
  # If you want to explicitly enable PipeWire (you might not need this if it's enabled elsewhere)
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };
  
  # Enable NetworkManager for networking
  networking.networkmanager.enable = true;
  
  # Set default applications for common file types
  xdg.mime.defaultApplications = {
    "application/pdf" = "org.gnome.Evince.desktop";
    "image/jpeg" = "ristretto.desktop";
    "image/png" = "ristretto.desktop";
    "text/plain" = "pluma.desktop";
    "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
    "application/zip" = "org.gnome.FileRoller.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };

  # Run polkit agent for authentication dialogs
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Set GTK theme for apps running as root
  security.sudo.extraConfig = ''
    Defaults env_keep += "GTK_THEME"
  '';
  
  # Tuning for better VM performance
  services.xserver.videoDrivers = [ "qxl" "vmware" "modesetting" "fbdev" ];
  boot.kernelParams = [ "nomodeset" "ibt=off" "boot.shell_on_fail" ];
}
