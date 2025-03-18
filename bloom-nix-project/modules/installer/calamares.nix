# modules/installer/calamares.nix
{ config, lib, pkgs, ... }:

let
  calamares-custom = pkgs.calamares.overrideAttrs (oldAttrs: {
    # Add debug output
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "-DCMAKE_BUILD_TYPE=Debug"
    ];
    
    # Ensure we have all needed dependencies
    buildInputs = (oldAttrs.buildInputs or []) ++ (with pkgs; [
      libsForQt5.kpmcore
      libsForQt5.kparts
      libsForQt5.kservice
      libsForQt5.kpackage
      parted
      gptfdisk
      e2fsprogs
      dosfstools
      ntfs3g
      xfsprogs
    ]);
    
    # Customize the installer
    postInstall = ''
      mkdir -p $out/share/calamares
      cp -R ${../../modules/installer/calamares}/* $out/share/calamares/
      
      # Create a launcher script with proper environment
      mkdir -p $out/bin
      mv $out/bin/calamares $out/bin/calamares-real
      cat > $out/bin/calamares << EOF
#!/bin/sh
# Set proper environment variables
export QT_QPA_PLATFORM=xcb
export QT_PLUGIN_PATH=${pkgs.libsForQt5.qt5.qtbase}/lib/qt-5/plugins
export QT_QUICK_CONTROLS_STYLE=org.kde.breeze

# Run installer with proper permissions
exec pkexec $out/bin/calamares-real -d "\$@" > /tmp/calamares.log 2>&1
EOF
      chmod +x $out/bin/calamares
    '';
  });
in {
  # Add Calamares to system packages
  environment.systemPackages = with pkgs; [
    calamares-custom
    # These packages help with hardware detection and installation
    gparted
    ntfs3g
    exfat
    dosfstools
    btrfs-progs
    f2fs-tools
    xfsprogs
    parted
    gptfdisk
    polkit  # Ensure polkit is available for authentication
  ];
  
  # Ensure polkit is configured properly
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program") == "/run/current-system/sw/bin/calamares-real") {
        return polkit.Result.YES;
      }
    });
  '';
  
  # Create desktop entry for Calamares with debugging
  environment.etc."xdg/autostart/calamares.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=Install Bloom Nix
    GenericName=System Installer
    Comment=Bloom Nix System Installer
    Exec=sh -c "calamares || xterm -e 'echo \"Installer failed. See logs at /tmp/calamares.log\"; cat /tmp/calamares.log; read -p \"Press Enter to close...\"'"
    Icon=calamares
    Terminal=false
    StartupNotify=true
    Categories=Qt;System;
  '';
}
