# modules/branding/default.nix (or add as a separate activation script)
{ config, lib, pkgs, ... }:

{
  system.activationScripts.wallpapers = ''
    mkdir -p /usr/share/plasma/wallpapers/bloom-nix
    cp -r ${./assets/wallpapers}/* /usr/share/plasma/wallpapers/bloom-nix/
  '';
  
  # Then set the default wallpaper via an environment file:
  environment.etc."plasma-wallpaper.conf".text = ''
    [Wallpaper]
    Image=/usr/share/plasma/wallpapers/bloom-nix/default.jpg
  '';
}
