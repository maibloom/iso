{ config, lib, pkgs, ... }:

let
  calamares-custom = pkgs.calamares.overrideAttrs (oldAttrs: {
    # Specify our custom configuration
    postInstall = ''
      mkdir -p $out/share/calamares
      cp -R ${../../modules/installer/calamares}/* $out/share/calamares/
    '';
  });
in {
  # Add Calamares to system packages
  environment.systemPackages = with pkgs; [
    calamares-custom
    libsForQt5.qt5.qtquickcontrols
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.plasma-framework
  ];
  
  # Create desktop entry for Calamares
  environment.etc."xdg/autostart/calamares.desktop".text = ''
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Bloom Nix
GenericName=System Installer
Comment=Bloom Nix System Installer
Exec=pkexec calamares
Icon=calamares
Terminal=false
StartupNotify=true
Categories=Qt;System;
  '';
}
