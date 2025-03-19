# modules/desktop/plasma-theme.nix


{ config, lib, pkgs, ... }:

{
  # Define a system-wide Plasma theme in the configuration
  environment.etc."xdg/kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
  '';
}