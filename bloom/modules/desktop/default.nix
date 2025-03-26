# Desktop configuration for Bloom Nix - KDE Plasma 6 with Wayland
{ config, lib, pkgs, ... }:

{
  # Import Wayland configuration
  imports = [ ./wayland.nix ];

  # Enable X11 server (required for KDE Plasma)
  services.xserver = {
    enable = true;
    
    # Configure display manager (login screen)
    displayManager = {
      sddm = {
        enable = true;
        # If possible, use Plasma 6 / Qt 6 version of SDDM
        package = pkgs.plasma5Packages.sddm;
        
        # Use Wayland by default
        wayland.enable = true;
        
        # Configure theme
        theme = "breeze";
        settings = {
          Theme = {
            CursorTheme = "breeze_cursors";
            Font = "Noto Sans,10,-1,5,50,0,0,0,0,0";
          };
        };
      };
      
      # Auto-login for the live environment
      autoLogin = {
        enable = true;
        user = "bloom";
      };
      
      # Default to Plasma Wayland session
      defaultSession = "plasmawayland";
    };
    
    # Configure KDE Plasma desktop
    desktopManager.plasma5 = {
      enable = true;
      # Additional Plasma configuration can go here
    };
  };
  
  # Essential KDE/Plasma packages
  environment.systemPackages = with pkgs; [
    # Core Plasma packages 
    plasma5Packages.plasma-workspace
    plasma5Packages.plasma-desktop
    plasma5Packages.plasma-nm
    plasma5Packages.plasma-pa
    plasma5Packages.kwayland
    plasma5Packages.kwin
    plasma5Packages.powerdevil
    
    # Essential KDE applications
    plasma5Packages.dolphin
    plasma5Packages.konsole
    plasma5Packages.kate
    plasma5Packages.ark
    plasma5Packages.spectacle
    plasma5Packages.gwenview
    plasma5Packages.okular
    
    # Web browser
    firefox-wayland
    
    # Theming
    breeze-icons
    breeze-qt5
    
    # Fonts
    noto-fonts
    noto-fonts-emoji
    
    # Tools for Wayland
    wl-clipboard
    
    # Media support
    vlc
    
    # System monitoring
    plasma5Packages.plasma-systemmonitor
  ];
  
  # Qt configuration for better Wayland support
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
  
  # Configure the black theme
  programs.dconf.enable = true;
  environment.etc."skel/.config/kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
    
    [Colors:View]
    BackgroundNormal=0,0,0
    
    [Colors:Window]
    BackgroundNormal=0,0,0
  '';
  
  # Sound configuration
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Enable XDG portals for better application integration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
  };
  
  # Enable flatpak for additional app support
  services.flatpak.enable = true;
  
  # Enable fonts
  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
  };
}
