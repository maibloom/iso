# KDE Plasma configuration for Bloom Nix
# This file configures either Plasma 5 or Plasma 6 depending on the usePlasma6 option
{ config, lib, pkgs, ... }:

let
  # Determine whether to use Plasma 6 or 5
  # Set to true to use Plasma 6, false for Plasma 5
  usePlasma6 = false;

  # Helper function to check if Plasma 6 is available in the nixpkgs version
  hasPlasma6 = builtins.hasAttr "plasma6" config.services.xserver.desktopManager;
  
  # Set the appropriate session name based on the Plasma version
  # Plasma 5 uses "plasmawayland" while Plasma 6 uses "plasma"
  defaultSession = if usePlasma6 && hasPlasma6 then "plasma" else "plasmawayland";
  
  # Determine which package namespace to use
  # Plasma 5 uses libsForQt5, Plasma 6 uses kdePackages
  pkgNamespace = if usePlasma6 && hasPlasma6 then pkgs.kdePackages else pkgs.libsForQt5;
in
{
  # Enable X11 server (required as fallback for Plasma Wayland)
  services.xserver.enable = true;
    
  # Configure display manager (login screen)
  services.xserver.displayManager = {
    sddm = {
      enable = true;
      # Enable Wayland support in SDDM
      wayland.enable = true;
      
      # Configure theme - this will be overridden by theme.nix if imported
      theme = "breeze";
    };
    
    # Auto-login for the live environment
    autoLogin = {
      enable = true;
      user = "bloom";
    };
    
    # Default to Plasma Wayland session
    defaultSession = defaultSession;
  };
 
  # Enable the appropriate Plasma desktop environment
  # This uses a conditional to select between Plasma 5 and 6
  services.xserver.desktopManager = if usePlasma6 && hasPlasma6 then {
    # Plasma 6 configuration (if available)
    plasma6.enable = true;

    # Explicitly disable Plasma 5 to avoid conflicts
    plasma5.enable = false;
  } else {
    # Plasma 5 configuration (fallback or if preferred)
    plasma5 = {
      enable = true;
      # Better HiDPI support in Plasma
      useQtScaling = true;
    };
  };
 
  # Essential KDE/Plasma packages
  environment.systemPackages = with pkgs; [
    # Core Plasma packages - these will use either kdePackages or libsForQt5
    # depending on which Plasma version we're using
    pkgNamespace.plasma-workspace
    pkgNamespace.plasma-desktop
    pkgNamespace.plasma-nm
    pkgNamespace.plasma-pa
    pkgNamespace.kwayland
    pkgNamespace.kwin
    pkgNamespace.powerdevil
    
    # Essential KDE applications
    pkgNamespace.dolphin
    pkgNamespace.konsole
    pkgNamespace.kate
    pkgNamespace.ark
    pkgNamespace.spectacle
    pkgNamespace.gwenview
    pkgNamespace.okular
    
    # Web browser with Wayland support
    firefox-wayland
    
    # Theming - these will be customized in theme.nix
    pkgNamespace.breeze-icons
    pkgNamespace.breeze-gtk
    
    # Additional Wayland-specific utilities
    wl-clipboard
    xdg-desktop-portal
    
    # Media support
    vlc
  ];
 
  # Qt configuration for better Wayland support
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
 
  # Sound configuration with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
 
  # Enable XDG portals for better application integration (screen sharing, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [
      # Use the appropriate portal implementation based on Plasma version
      (if usePlasma6 && hasPlasma6 then pkgs.kdePackages.xdg-desktop-portal-kde else pkgs.libsForQt5.xdg-desktop-portal-kde)
    ];
    config.common.default = "kde";
  };
 
  # Enable flatpak for additional app support
  services.flatpak.enable = true;
 
  # Set Wayland-specific environment variables
  environment.sessionVariables = {
    # Encourage applications to use Wayland where possible
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    
    # For better compatibility with some applications
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
  };
  
  # Documentation about Plasma versions
  environment.etc."bloom-nix/docs/plasma-versions.txt".text = ''
    Bloom Nix Plasma Configuration
    =============================
    
    This distribution currently uses ${if usePlasma6 && hasPlasma6 then "Plasma 6" else "Plasma 5"} as its desktop environment.
    
    Plasma 5:
    - More mature and stable
    - Wider hardware compatibility
    - Compatible with more extensions and themes
    
    Plasma 6:
    - Newer features and improvements
    - Better Wayland integration
    - Uses Qt 6 instead of Qt 5
    - More future-proof but may have some rough edges
    
    To change the Plasma version, modify the 'usePlasma6' setting in
    /etc/nixos/modules/plasma.nix and rebuild.
  '';
}
