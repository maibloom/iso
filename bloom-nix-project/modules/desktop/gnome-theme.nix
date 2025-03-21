{ config, lib, pkgs, ... }:

let
  colors = {
    background = "#454d6e";
    panel = "#2d2d2d";  # Your desired taskbar color
  };
in {
  # Force the branding image paths
  environment.etc."bloom-nix/backgrounds/default.jpg".source =
    lib.mkForce ../../branding/default.jpg;
  environment.etc."bloom-nix/backgrounds/login.jpg".source =
    lib.mkForce ../../branding/login-background.png;

  # Make the backgrounds directory available (forced)
  environment.etc."gnome/backgrounds/branding".source =
    lib.mkForce ../../branding/backgrounds;

  # Force GNOME wallpaper configuration
  environment.etc."gnome/settings-daemon/plugins/background/uri".text =
    lib.mkForce "/etc/gnome/backgrounds/branding/background.png";

  # Force GNOME color scheme
  environment.etc."xdg/color-schemes/Bloom.colors".text =
    lib.mkForce ''
      [Colors:View]
      BackgroundNormal=${colors.background}

      [Colors:Window]
      BackgroundNormal=${colors.background}

      [Colors:Panel]
      BackgroundNormal=${colors.panel}
    '';

  # Force GNOME global settings
  environment.etc."xdg/gnome-settings-daemon".text =
    lib.mkForce ''
      [General]
      ColorScheme=Bloom

      [GNOME]
      LookAndFeelPackage=org.gnome.shell

      [Icons]
      Theme=Adwaita-dark
    '';

  # Ensure GNOME session reads the new theme settings on startup
  system.activationScripts.gnomeThemeSetup = {
    text = ''
      echo "Applying forced GNOME theme settings..."
      mkdir -p /usr/share/color-schemes
      cp -n /etc/xdg/color-schemes/Bloom.colors /usr/share/color-schemes/ || true
    '';
  };

  # Enable GNOME desktop environment (force GNOME Shell to use Adwaita-dark)
  services.xserver.desktopManager.gnome.enable = true;
}
