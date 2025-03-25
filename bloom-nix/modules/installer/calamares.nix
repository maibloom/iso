{ config, lib, pkgs, ... }:

{
  # Make Calamares available in the system
  environment.systemPackages = with pkgs; [
    calamares-nixos
  ];
  
  # Create a desktop entry for Calamares
  environment.etc."xdg/autostart/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install Bloom Nix
    GenericName=System Installer
    Comment=Calamares — System Installer for Bloom Nix
    Exec=pkexec calamares
    Icon=calamares
    Terminal=false
    StartupNotify=true
    Categories=Qt;System;
  '';
}
