{ config, lib, pkgs, ... }:

let
  # Define our color scheme variables for easy reference
  colors = {
    background = "#454d6e";
    foreground = "#f1efee";
    accent1 = "#ab6470";
    accent2 = "#999a5e";
    inactive = "#989cad";
  };
in
{
  # Make branding images accessible from the correct paths
  environment.etc = {
    # Wallpaper and login images - sourced directly from branding directory
    # Use lib.mkForce to override any conflicting definitions
    "bloom-nix/backgrounds/default.jpg".source = lib.mkForce ../../branding/default.jpg;
    "bloom-nix/backgrounds/login.jpg".source = lib.mkForce ../../branding/sddm-background.png;
    
    # Global color scheme
    "xdg/color-schemes/Bloom.colors".text = ''
      [ColorEffects:Disabled]
      Color=${colors.inactive}
      ColorAmount=0.55
      ColorEffect=2
      ContrastAmount=0.65
      ContrastEffect=1
      IntensityAmount=0.1
      IntensityEffect=0

      [ColorEffects:Inactive]
      ChangeSelectionColor=false
      Color=${colors.inactive}
      ColorAmount=0.05
      ColorEffect=2
      ContrastAmount=0.2
      ContrastEffect=2
      IntensityAmount=0
      IntensityEffect=0

      [Colors:Button]
      BackgroundAlternate=${colors.background}
      BackgroundNormal=${colors.background}
      DecorationFocus=${colors.accent1}
      DecorationHover=${colors.accent1}
      ForegroundActive=${colors.accent2}
      ForegroundInactive=${colors.inactive}
      ForegroundLink=${colors.accent1}
      ForegroundNegative=#ff6d6d
      ForegroundNeutral=#ffbd8a
      ForegroundNormal=${colors.foreground}
      ForegroundPositive=${colors.accent2}
      ForegroundVisited=#a28cc6

      [Colors:Selection]
      BackgroundAlternate=${colors.accent1}
      BackgroundNormal=${colors.accent1}
      DecorationFocus=${colors.accent1}
      DecorationHover=${colors.accent1}
      ForegroundActive=${colors.foreground}
      ForegroundInactive=${colors.foreground}
      ForegroundLink=${colors.foreground}
      ForegroundNegative=#ff6d6d
      ForegroundNeutral=#ffbd8a
      ForegroundNormal=${colors.foreground}
      ForegroundPositive=${colors.accent2}
      ForegroundVisited=${colors.foreground}

      [Colors:Tooltip]
      BackgroundAlternate=${colors.background}
      BackgroundNormal=${colors.background}
      DecorationFocus=${colors.accent1}
      DecorationHover=${colors.accent1}
      ForegroundActive=${colors.accent2}
      ForegroundInactive=${colors.inactive}
      ForegroundLink=${colors.accent1}
      ForegroundNegative=#ff6d6d
      ForegroundNeutral=#ffbd8a
      ForegroundNormal=${colors.foreground}
      ForegroundPositive=${colors.accent2}
      ForegroundVisited=#a28cc6

      [Colors:View]
      BackgroundAlternate=#3a4161
      BackgroundNormal=${colors.background}
      DecorationFocus=${colors.accent1}
      DecorationHover=${colors.accent1}
      ForegroundActive=${colors.accent2}
      ForegroundInactive=${colors.inactive}
      ForegroundLink=${colors.accent1}
      ForegroundNegative=#ff6d6d
      ForegroundNeutral=#ffbd8a
      ForegroundNormal=${colors.foreground}
      ForegroundPositive=${colors.accent2}
      ForegroundVisited=#a28cc6

      [Colors:Window]
      BackgroundAlternate=${colors.background}
      BackgroundNormal=${colors.background}
      DecorationFocus=${colors.accent1}
      DecorationHover=${colors.accent1}
      ForegroundActive=${colors.accent2}
      ForegroundInactive=${colors.inactive}
      ForegroundLink=${colors.accent1}
      ForegroundNegative=#ff6d6d
      ForegroundNeutral=#ffbd8a
      ForegroundNormal=${colors.foreground}
      ForegroundPositive=${colors.accent2}
      ForegroundVisited=#a28cc6

      [General]
      ColorScheme=Bloom
      Name=Bloom
      accentActiveTitlebar=false
      shadeSortColumn=true

      [KDE]
      contrast=4

      [WM]
      activeBackground=${colors.background}
      activeBlend=${colors.background}
      activeForeground=${colors.foreground}
      inactiveBackground=${colors.background}
      inactiveBlend=${colors.background}
      inactiveForeground=${colors.inactive}
    '';

    # System-wide KDE global configuration for dark theme
    "xdg/kdeglobals".text = ''
      [General]
      ColorScheme=Bloom

      [KDE]
      LookAndFeelPackage=org.kde.breezedark.desktop

      [Icons]
      Theme=breeze-dark
    '';

    # KWin (window manager) configuration
    "xdg/kwinrc".text = ''
      [org.kde.kdecoration2]
      library=org.kde.breeze
      theme=Breeze
      blur-background=true
     
      [Effect-Blur]
      BlurStrength=15
      NoiseStrength=5

      [Plugins]
      blurEnabled=true
     
      [Compositing]
      AnimationSpeed=3
      Backend=OpenGL
      Enabled=true
      GLCore=true
      GLTextureFilter=2
      HiddenPreviews=5
      OpenGLIsUnsafe=false
      WindowsBlockCompositing=true
      XRenderSmoothScale=false
    '';

    # Configure Konsole terminal with themed colors
    "xdg/konsolerc".text = ''
      [Desktop Entry]
      DefaultProfile=Bloom.profile

      [Favorite Profiles]
      Favorites=Bloom.profile
    '';

    "xdg/konsole/Bloom.profile".text = ''
      [Appearance]
      ColorScheme=Bloom
      Font=Noto Sans Mono,11,-1,5,50,0,0,0,0,0

      [General]
      Name=Bloom
      Parent=FALLBACK/
    '';

    "xdg/konsole/Bloom.colorscheme".text = ''
      [Background]
      Color=${colors.background}

      [BackgroundFaint]
      Color=${colors.background}

      [BackgroundIntense]
      Color=${colors.background}

      [Color0]
      Color=#3a3a3a

      [Color0Faint]
      Color=#3a3a3a

      [Color0Intense]
      Color=#666666

      [Color1]
      Color=${colors.accent1}

      [Color1Faint]
      Color=#8c555d

      [Color1Intense]
      Color=#ff7b8a

      [Color2]
      Color=${colors.accent2}

      [Color2Faint]
      Color=#7c7c4e

      [Color2Intense]
      Color=#b8b968

      [Color3]
      Color=#c98a5a

      [Color3Faint]
      Color=#a57449

      [Color3Intense]
      Color=#ffa569

      [Color4]
      Color=#3e6cab

      [Color4Faint]
      Color=#325888

      [Color4Intense]
      Color=#5c8ed6

      [Color5]
      Color=#8b6aa9

      [Color5Faint]
      Color=#6e5487

      [Color5Intense]
      Color=#a978cc

      [Color6]
      Color=#56a4a1

      [Color6Faint]
      Color=#468583

      [Color6Intense]
      Color=#67cac7

      [Color7]
      Color=${colors.foreground}

      [Color7Faint]
      Color=#d0cfcc

      [Color7Intense]
      Color=#ffffff

      [Foreground]
      Color=${colors.foreground}

      [ForegroundFaint]
      Color=#d0cfcc

      [ForegroundIntense]
      Color=#ffffff

      [General]
      Blur=true
      Description=Bloom
      Opacity=0.9
      Wallpaper=
    '';
  };
  
  # Template configurations for new users
  environment.etc."skel/.config/kdeglobals".text = ''
    [General]
    ColorScheme=Bloom

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
    
    [Icons]
    Theme=breeze-dark
  '';
  
  environment.etc."skel/.config/plasmarc".text = ''
    [Theme]
    name=breeze-dark
  '';
  
  environment.etc."skel/.config/plasma-org.kde.plasma.desktop-appletsrc".text = ''
    [Containments][1]
    activityId=
    formfactor=2
    immutability=1
    lastScreen=0
    location=4
    plugin=org.kde.panel
    wallpaperplugin=org.kde.image

    [Containments][1][Applets][2]
    immutability=1
    plugin=org.kde.plasma.kickoff

    [Containments][1][Applets][3]
    immutability=1
    plugin=org.kde.plasma.pager

    [Containments][1][Applets][4]
    immutability=1
    plugin=org.kde.plasma.icontasks

    [Containments][1][Applets][5]
    immutability=1
    plugin=org.kde.plasma.marginsseparator

    [Containments][1][Applets][6]
    immutability=1
    plugin=org.kde.plasma.systemtray

    [Containments][1][Applets][7]
    immutability=1
    plugin=org.kde.plasma.digitalclock

    [Containments][1][Applets][8]
    immutability=1
    plugin=org.kde.plasma.showdesktop

    [Containments][1][General]
    AppletOrder=2;3;4;5;6;7;8
    blur=true
    panelOpacity=0.5
    panelTransparency=50
    shadowOpacity=60
    shadowSize=45
    shadows=All
    solidBackgroundForMaximized=true
    
    [Containments][2]
    activityId=
    formfactor=0
    immutability=1
    lastScreen=0
    location=0
    plugin=org.kde.plasma.folder
    wallpaperplugin=org.kde.image
    
    [Containments][2][Wallpaper][org.kde.image][General]
    Image=file:///etc/bloom-nix/backgrounds/default.jpg
    FillMode=2
  '';

  # Configure SDDM login manager
  services.xserver.displayManager.sddm = {
    theme = "breeze";
    settings = {
      Theme = {
        # Set theme and background
        Current = "breeze";
        CursorTheme = "breeze_cursors";
        Font = "Noto Sans,10,-1,5,50,0,0,0,0,0";
        # Use custom background
        Background = "/etc/bloom-nix/backgrounds/login.jpg";
        # Set dark color scheme directly in the Theme section
        ColorScheme = "BreezeDark";
      };
      X11 = {
        # Better display scaling support
        EnableHiDPI = true;
        ServerArguments = "-dpi 96 -nolisten tcp";
      };
    };
  };

  # Create script to apply theme on first login - updated for KDE Plasma 6
  environment.systemPackages = with pkgs; [
    # Include dark theme packages
    kdePackages.breeze-plymouth
    kdePackages.breeze
    kdePackages.oxygen-sounds
    
    (writeShellScriptBin "bloom-theme-setup" ''
      #!/bin/sh
      # Create log file for debugging
      LOGFILE="/tmp/bloom-theme-setup.log"
      mkdir -p "$(dirname "$LOGFILE")"
      exec > >(tee -a "$LOGFILE") 2>&1
      echo "========================================"
      echo "Starting Bloom theme setup at $(date)"
      echo "========================================"
      
      # Determine which config tool to use (Plasma 6 uses kwriteconfig6)
      if command -v kwriteconfig6 &> /dev/null; then
        CONFIG_TOOL="kwriteconfig6"
        echo "Using Plasma 6 configuration tool"
      else
        CONFIG_TOOL="kwriteconfig5"
        echo "Falling back to Plasma 5 configuration tool"
      fi
      
      # Apply color scheme
      echo "Setting color scheme..."
      $CONFIG_TOOL --file kdeglobals --group General --key ColorScheme "Bloom"
      
      # Apply dark theme
      echo "Setting dark theme..."
      $CONFIG_TOOL --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"
      $CONFIG_TOOL --file kdeglobals --group Icons --key Theme "breeze-dark"
      $CONFIG_TOOL --file plasmarc --group Theme --key name "breeze-dark"
      
      # Set wallpaper
      echo "Setting wallpaper..."
      if command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage /etc/bloom-nix/backgrounds/default.jpg
        echo "Wallpaper set with plasma-apply-wallpaperimage"
      else
        echo "Using DBus method for wallpaper..."
        dbus-send --session --dest=org.kde.plasmashell --type=method_call \
          /PlasmaShell org.kde.PlasmaShell.evaluateScript "string: \
          var allDesktops = desktops(); \
          for (i=0;i<allDesktops.length;i++) { \
            d = allDesktops[i]; \
            d.wallpaperPlugin = 'org.kde.image'; \
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General'); \
            d.writeConfig('Image', 'file:///etc/bloom-nix/backgrounds/default.jpg'); \
            d.writeConfig('FillMode', '2'); \
          }"
      fi
      
      # Configure panel transparency
      echo "Configuring panel transparency..."
      $CONFIG_TOOL --file plasma-org.kde.plasma.desktop-appletsrc --group "Containments" --group "1" --group "General" --key "panelOpacity" "0.5"
      $CONFIG_TOOL --file plasma-org.kde.plasma.desktop-appletsrc --group "Containments" --group "1" --group "General" --key "blur" "true"
      
      # Set blur effect
      echo "Setting blur effects..."
      $CONFIG_TOOL --file kwinrc --group Plugins --key blurEnabled "true"
      $CONFIG_TOOL --file kwinrc --group "Effect-Blur" --key BlurStrength "15"
      
      # Verify theme files exist
      echo "Verifying theme files..."
      if [ -f "/etc/bloom-nix/backgrounds/default.jpg" ]; then
        echo "Default wallpaper exists"
      else
        echo "WARNING: Default wallpaper not found"
      fi
      
      if [ -f "/etc/bloom-nix/backgrounds/login.jpg" ]; then
        echo "Login background exists"
      else
        echo "WARNING: Login background not found"
      fi
      
      # Restart Plasma to apply changes
      echo "Restarting Plasma shell..."
      if pgrep -x "plasmashell" > /dev/null; then
        killall plasmashell
        sleep 2
        if command -v kstart6 &> /dev/null; then
          kstart6 plasmashell
        else
          kstart5 plasmashell
        fi
      fi
      
      echo "Theme setup completed at $(date)"
      echo "Log saved to $LOGFILE"
    '')
  ];

  # Auto-start the theme setup on first login
  environment.etc."xdg/autostart/bloom-theme-setup.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bloom Theme Setup
    Comment=Sets up the Bloom theme
    Exec=/run/current-system/sw/bin/bloom-theme-setup
    Terminal=false
    X-KDE-autostart-phase=1
    OnlyShowIn=KDE;Plasma;
  '';
  
  # System activation to prepare theme files
  system.activationScripts.bloomThemeSetup = {
    text = ''
      # Create necessary directories for theme files
      mkdir -p /usr/share/color-schemes
      mkdir -p /usr/share/konsole
      
      # Copy color scheme to standard KDE locations
      cp -f /etc/xdg/color-schemes/Bloom.colors /usr/share/color-schemes/ || true
      
      # Make sure backgrounds directory exists
      mkdir -p /etc/bloom-nix/backgrounds
      
      # Copy konsole themes
      cp -f /etc/xdg/konsole/Bloom.colorscheme /usr/share/konsole/ || true
    '';
    deps = [];
  };
}
