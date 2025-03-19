# modules/desktop/plasma-theme.nix
{ config, pkgs, ... }:

let
  # Define branding assets as a store path
  branding = pkgs.runCommand "branding" {} ''
    mkdir -p $out
    cp -r ${./../../branding}/* $out/
  '';

  # Define custom color scheme as a derivation
  customColors = pkgs.writeTextDir "share/color-schemes/custom-colors.colors" ''
    [Colors:Window]
    BackgroundNormal=#454d6e
    ForegroundNormal=#f1efee

    [Colors:Button]
    BackgroundNormal=#999a5e
    ForegroundNormal=#f1efee

    [Colors:Selection]
    BackgroundNormal=#ab6470
    ForegroundNormal=#f1efee
  '';
in {
  # Enable Plasma Desktop
  services.xserver.desktopManager.plasma5.enable = true;

  # Set Plasma theme and color scheme
  services.xserver.desktopManager.plasma5.kdeglobals = {
    KDE = {
      LookAndFeelPackage = "custom-dark";  # Assuming "custom-dark" is installed
    };
    General = {
      ColorScheme = "custom-colors";
    };
  };

  # Include custom color scheme in system packages
  environment.systemPackages = [ customColors ];

  # Custom wallpaper setup (commented out as it may not work system-wide)
  # environment.etc."plasma-workspace/env/wallpaper.sh".text =
  #   let wallpaper = "${branding}/default.jpg";
  #   in ''export WALLPAPER=${wallpaper}'';

  # SDDM login screen customization
  services.displayManager.sddm = {
    enable = true;
    theme = "breeze";  # Use default breeze theme as base
    settings = {
      Theme = {
        Background = "${branding}/sddm-background.png";
        Font = "Noto Sans";
        FontSize = "10";
      };
    };
  };

  # Custom loading screen (Plymouth)
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
    themePackages = [ (pkgs.stdenv.mkDerivation {
      name = "bloom-plymouth-theme";
      src = pkgs.plymouth;  # Use the default Plymouth theme as a base
      installPhase = ''
        mkdir -p $out/share/plymouth/themes/bloom
        cp -r $src/share/plymouth/themes/text/* $out/share/plymouth/themes/bloom
        cp ${branding}/splash.png $out/share/plymouth/themes/bloom/bgrt.png
      '';
    })];
  };

  # Basic UI customizations
  environment.variables = {
    QT_STYLE_OVERRIDE = "breeze";
    XCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
  };
}
