# modules/desktop/plasma-theme.nix
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
  # Configure KDE Plasma theme settings
  environment.etc = {
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

    # Configure KDE Plasma desktop with transparent panel
    "xdg/plasma-desktop-appletsrc".text = ''
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

    # Configure KWin (window manager) settings
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
      Font=Fira Code,11,-1,5,50,0,0,0,0,0

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

  # Create script to apply theme on first login - updated for KDE Plasma 6
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "bloom-theme-setup" ''
      #!/bin/sh
      # Apply Bloom theme settings for KDE Plasma 6
      
      # Set color scheme
      lookandfeeltool -a org.kde.breeze.desktop
      
      # For Plasma 6, we need to use the new config tool (if available)
      if command -v plasma-apply-colorscheme &> /dev/null; then
        plasma-apply-colorscheme Bloom
      else
        # Fall back to the older KDE 5 method
        kwriteconfig5 --file kdeglobals --group General --key ColorScheme Bloom
      fi
      
      # Set wallpaper - try Plasma 6 method first
      if command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage /etc/bloom-nix/backgrounds/default.jpg
      else
        # Fall back to older method
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
      
      # Configure panel transparency - adapt to Plasma 6 if needed
      for config_tool in kwriteconfig6 kwriteconfig5; do
        if command -v $config_tool &> /dev/null; then
          $config_tool --file plasma-org.kde.plasma.desktop-appletsrc --group "Containments" --group "1" --group "General" --key "panelOpacity" "0.5"
          $config_tool --file plasma-org.kde.plasma.desktop-appletsrc --group "Containments" --group "1" --group "General" --key "blur" "true"
          $config_tool --file kwinrc --group Plugins --key blurEnabled "true"
          $config_tool --file kwinrc --group Effect-Blur --key BlurStrength "15"
          break
        fi
      done
      
      # Restart Plasma to apply changes - check for Plasma 6 first
      if pgrep -x "plasmashell" > /dev/null; then
        killall plasmashell
        if command -v kstart6 &> /dev/null; then
          kstart6 plasmashell
        else
          kstart5 plasmashell
        fi
      fi
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
  '';
}
