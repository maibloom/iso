{ config, lib, pkgs, ... }:

{
  # Enable X11 server
  services.xserver.enable = true;
  
  # Configure display manager
  services.xserver.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
    };
    
    # Auto-login for the live environment
    autoLogin = {
      enable = true;
      user = "bloom";
    };
    
    # Default to Plasma Wayland session
    defaultSession = "plasmawayland";
  };
  
  # Enable Plasma 5 with minimal options
  services.xserver.desktopManager.plasma5 = {
    enable = true;
    useQtScaling = true;
  };
  
  # Core desktop packages only
  environment.systemPackages = with pkgs; [
    # Essential applications
    libsForQt5.dolphin
    libsForQt5.konsole
    libsForQt5.kate
    firefox-wayland
    
    # Basic system utilities
    libsForQt5.ark
    libsForQt5.spectacle
    
    # Theming
    libsForQt5.breeze-icons
    libsForQt5.breeze-qt5
    libsForQt5.breeze-gtk
    
    # Fonts
    noto-fonts
    noto-fonts-emoji
    
    # Wayland support
    wl-clipboard
  ];
  
  # Configure the desktop theme
  environment.etc."skel/.config/kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
  '';
  
  # Font configuration
  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    enableGhostscriptFonts = false;  # Reduce bloat
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
    ];
  };
  
  # XDG portals for application integration
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.libsForQt5.xdg-desktop-portal-kde ];
    config.common.default = "kde";
  };
  
  # Minimal environment variables for Wayland
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
  };
}
