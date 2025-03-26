# Custom package definitions and overrides for Bloom Nix
{ pkgs ? import <nixpkgs> {} }:

rec {
  # Import standard packages
  inherit (pkgs) 
    firefox
    vim
    git
    htop
    curl;
  
  # Custom packages or overrides can be defined here
  
  # Example: A customized Firefox with specific settings
  bloom-firefox = pkgs.firefox.override {
    extraPrefs = ''
      // Bloom Nix specific Firefox preferences
      pref("browser.startup.homepage", "https://bloom-nix.org");
      pref("browser.startup.homepage_welcome_url", "https://bloom-nix.org/welcome");
      pref("browser.newtabpage.pinned", "[{\"url\":\"https://bloom-nix.org\",\"title\":\"Bloom Nix\"}]");
      
      // Privacy settings
      pref("privacy.trackingprotection.enabled", true);
      pref("privacy.trackingprotection.socialtracking.enabled", true);
      pref("privacy.trackingprotection.cryptomining.enabled", true);
      pref("privacy.trackingprotection.fingerprinting.enabled", true);
      
      // Performance settings
      pref("browser.cache.disk.enable", true);
      pref("browser.cache.memory.enable", true);
      pref("browser.cache.memory.capacity", 65536);
    '';
  };
  
  # Example: A custom welcome application for Bloom Nix
  bloom-welcome = pkgs.stdenv.mkDerivation {
    name = "bloom-welcome";
    version = "1.0";
    
    src = ./welcome;
    
    nativeBuildInputs = with pkgs; [
      makeWrapper
      qt5.wrapQtAppsHook
    ];
    
    buildInputs = with pkgs; [
      qt5.qtbase
      qt5.qtdeclarative
      qt5.qtsvg
    ];
    
    installPhase = ''
      mkdir -p $out/bin $out/share/applications $out/share/bloom-welcome
      
      cp -r resources $out/share/bloom-welcome/
      install -Dm755 bloom-welcome $out/bin/bloom-welcome
      
      makeWrapper $out/bin/bloom-welcome $out/bin/bloom-welcome-wrapped \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"
      
      # Create desktop entry
      cat > $out/share/applications/bloom-welcome.desktop << EOF
      [Desktop Entry]
      Type=Application
      Name=Welcome to Bloom Nix
      Comment=Discover Bloom Nix
      Exec=$out/bin/bloom-welcome-wrapped
      Icon=$out/share/bloom-welcome/resources/logo.png
      Terminal=false
      Categories=System;
      StartupNotify=true
      EOF
    '';
    
    meta = with pkgs.lib; {
      description = "Welcome application for Bloom Nix";
      homepage = "https://bloom-nix.org";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
  
  # Meta-packages for different profiles
  bloom-desktop-base = pkgs.buildEnv {
    name = "bloom-desktop-base";
    paths = with pkgs; [
      firefox
      libreoffice-qt
      thunderbird
      gimp
      vlc
      telegram-desktop
      discord
    ];
  };
  
  # Gaming profile
  bloom-gaming = pkgs.buildEnv {
    name = "bloom-gaming";
    paths = with pkgs; [
      steam
      lutris
      wine
      winetricks
      gamemode
      mangohud
      protontricks
    ];
  };
  
  # Development profile
  bloom-development = pkgs.buildEnv {
    name = "bloom-development";
    paths = with pkgs; [
      vscode
      git
      gnumake
      gcc
      clang
      python3
      nodejs
      rustup
      go
    ];
  };
  
  # Scientific computing profile
  bloom-science = pkgs.buildEnv {
    name = "bloom-science";
    paths = with pkgs; [
      R
      rstudio
      python3
      python3Packages.numpy
      python3Packages.scipy
      python3Packages.matplotlib
      python3Packages.pandas
      python3Packages.jupyter
      octave
      gnuplot
    ];
  };
  
  # Media production profile
  bloom-media = pkgs.buildEnv {
    name = "bloom-media";
    paths = with pkgs; [
      blender
      inkscape
      gimp
      kdenlive
      audacity
      obs-studio
      ffmpeg
    ];
  };
}
