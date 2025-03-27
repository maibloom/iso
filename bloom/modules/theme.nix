# Theme configuration for Bloom Nix
# This file handles visual customization for the KDE Plasma desktop
{ config, lib, pkgs, ... }:

let
  # Define brand colors for the distribution
  # These can be easily changed to rebrand the entire system
  bloomColors = {
    primary = "#FF5F15";    # Orange primary color
    secondary = "#3C0061";  # Purple secondary color
    background = "#0F0F0F"; # Very dark gray, almost black
    foreground = "#F9F9F9"; # Very light gray, almost white
    accent = "#00B4D8";     # Cyan accent color
  };
  
  # Determine which package namespace to use for theming (matches plasma.nix)
  # This dynamically detects whether Plasma 6 is available
  hasPlasma6 = builtins.hasAttr "plasma6" config.services.xserver.desktopManager;
  usePlasma6 = if hasPlasma6 then config.services.xserver.desktopManager.plasma6.enable else false;
  pkgNamespace = if usePlasma6 then pkgs.kdePackages else pkgs.libsForQt5;
in {
  # Install required theme packages
  environment.systemPackages = with pkgs; [
    # Core theming packages
    pkgNamespace.breeze
    pkgNamespace.breeze-gtk
    pkgNamespace.breeze-icons
    
    # Additional icon themes
    papirus-icon-theme
    
    # Cursor themes
    pkgNamespace.breeze-plymouth
    
    # Fonts
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    liberation_ttf
    fira-code
    fira-code-symbols
    
    # Plymouth boot splash theme
    plymouth
  ];
  
  # Font configuration
  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
    
    # Default font configuration
    fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans" "Liberation Sans" ];
      serif = [ "Noto Serif" "Liberation Serif" ];
      monospace = [ "Fira Code" "Liberation Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  
  # Configure the SDDM login screen theme
  services.xserver.displayManager.sddm = {
    theme = "breeze";
    settings = {
      Theme = {
        # Set cursor and font for the login screen
        CursorTheme = "breeze_cursors";
        Font = "Noto Sans,10,-1,5,50,0,0,0,0,0";
      };
      # Color settings for SDDM
      X11 = {
        # Use the Bloom colors for the login screen
        ServerArguments = "-background ${bloomColors.background}";
      };
    };
  };
  
  # Configure Plymouth boot splash
  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };

  # Setting up KDE Plasma global theme via config files
  # These files will be placed in the user's home directory during setup
  
  # Global KDE configuration (colors, theme, etc.)
  environment.etc."skel/.config/kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    Name=Breeze Dark
    shadeSortColumn=true

    [Icons]
    Theme=breeze-dark

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
    SingleClick=false
    
    [Colors:View]
    BackgroundNormal=${bloomColors.background}
    ForegroundNormal=${bloomColors.foreground}
    
    [Colors:Window]
    BackgroundNormal=${bloomColors.background}
    ForegroundNormal=${bloomColors.foreground}
    
    [Colors:Button]
    BackgroundNormal=${bloomColors.secondary}
    ForegroundNormal=${bloomColors.foreground}
    
    [Colors:Selection]
    BackgroundNormal=${bloomColors.primary}
    ForegroundNormal=${bloomColors.foreground}
    
    [Colors:Tooltip]
    BackgroundNormal=${bloomColors.secondary}
    ForegroundNormal=${bloomColors.foreground}
    
    [Colors:Complementary]
    BackgroundNormal=${bloomColors.background}
    ForegroundNormal=${bloomColors.foreground}
    
    [WM]
    activeBackground=${bloomColors.primary}
    activeForeground=${bloomColors.foreground}
    inactiveBackground=${bloomColors.background}
    inactiveForeground=${bloomColors.foreground}
  '';
  
  # Plasma desktop configuration
  environment.etc."skel/.config/plasmarc".text = ''
    [Theme]
    name=breeze-dark
    
    [Wallpapers]
    usersWallpapers=/usr/share/wallpapers/
  '';
  
  # Configure the window decoration
  environment.etc."skel/.config/kwinrc".text = ''
    [org.kde.kdecoration2]
    library=org.kde.breeze
    theme=Breeze
    
    [Windows]
    Placement=Centered
    
    [Effect-Blur]
    BlurStrength=12
    
    [Plugins]
    blurEnabled=true
    kwin4_effect_fadingpopupsEnabled=false
    kwin4_effect_dialogparentEnabled=true
    kwin4_effect_translucencyEnabled=true
    kwin4_effect_wobblywindowsEnabled=false
  '';
  
  # Create a custom welcome wallpaper
  # In a real implementation, you would provide your own wallpaper file
  # For now, we'll just create a configuration that would use it
  environment.etc."skel/.config/plasma-org.kde.plasma.desktop-appletsrc".text = ''
    [Containments][1]
    activityId=
    formfactor=0
    immutability=1
    lastScreen=0
    location=0
    plugin=org.kde.plasma.folder
    wallpaperplugin=org.kde.image
    
    [Containments][1][Wallpaper][org.kde.image][General]
    Image=/usr/share/wallpapers/bloom-nix-default.jpg
    FillMode=2
  '';
  
  # Configure the Konsole terminal with custom colors
  environment.etc."skel/.config/konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=Bloom.profile
    
    [MainWindow]
    MenuBar=Disabled
    ToolBarsMovable=Disabled
  '';
  
  # Create a custom Konsole profile with the Bloom colors
  environment.etc."skel/.local/share/konsole/Bloom.profile".text = ''
    [Appearance]
    ColorScheme=Bloom
    Font=Fira Code,11,-1,5,50,0,0,0,0,0
    
    [General]
    Name=Bloom
    Parent=FALLBACK/
    
    [Scrolling]
    HistoryMode=2
    ScrollBarPosition=2
  '';
  
  # Create a custom Konsole color scheme
  environment.etc."skel/.local/share/konsole/Bloom.colorscheme".text = ''
    [Background]
    Color=${bloomColors.background}
    
    [BackgroundFaint]
    Color=${bloomColors.background}
    
    [BackgroundIntense]
    Color=${bloomColors.background}
    
    [Color0]
    Color=35,38,39
    
    [Color0Faint]
    Color=49,54,59
    
    [Color0Intense]
    Color=127,140,141
    
    [Color1]
    Color=237,21,21
    
    [Color1Faint]
    Color=120,50,40
    
    [Color1Intense]
    Color=192,57,43
    
    [Color2]
    Color=17,209,22
    
    [Color2Faint]
    Color=23,162,98
    
    [Color2Intense]
    Color=28,220,154
    
    [Color3]
    Color=246,116,0
    
    [Color3Faint]
    Color=182,86,25
    
    [Color3Intense]
    Color=${bloomColors.primary}
    
    [Color4]
    Color=29,153,243
    
    [Color4Faint]
    Color=27,102,143
    
    [Color4Intense]
    Color=${bloomColors.accent}
    
    [Color5]
    Color=155,89,182
    
    [Color5Faint]
    Color=97,74,115
    
    [Color5Intense]
    Color=${bloomColors.secondary}
    
    [Color6]
    Color=26,188,156
    
    [Color6Faint]
    Color=24,108,96
    
    [Color6Intense]
    Color=22,160,133
    
    [Color7]
    Color=252,252,252
    
    [Color7Faint]
    Color=99,104,109
    
    [Color7Intense]
    Color=255,255,255
    
    [Foreground]
    Color=${bloomColors.foreground}
    
    [ForegroundFaint]
    Color=239,240,241
    
    [ForegroundIntense]
    Color=255,255,255
    
    [General]
    Blur=false
    ColorRandomization=false
    Description=Bloom
    Opacity=1
    Wallpaper=
  '';
  
  # Additional setup script to apply theme settings for new users
  system.activationScripts.bloomTheme = ''
    # Script to apply theme settings for new users
    # These settings will be copied to the home directory of any new user
    
    # Ensure the themes directory exists
    mkdir -p /etc/skel/.themes
    mkdir -p /etc/skel/.icons
    mkdir -p /etc/skel/.local/share/konsole
    
    # Create a file that will set the GTK theme on login
    mkdir -p /etc/skel/.config/gtk-3.0
    echo '[Settings]
    gtk-theme-name=Breeze-Dark
    gtk-icon-theme-name=breeze-dark
    gtk-font-name=Noto Sans 10
    gtk-cursor-theme-name=breeze_cursors
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=true' > /etc/skel/.config/gtk-3.0/settings.ini
    
    # Create similar settings for GTK4
    mkdir -p /etc/skel/.config/gtk-4.0
    cp /etc/skel/.config/gtk-3.0/settings.ini /etc/skel/.config/gtk-4.0/
  '';
}
