# modules/branding/default.nix
{ config, lib, pkgs, ... }:

{
  # System identification files - full rebranding from NixOS to Bloom Nix
  environment.etc."os-release".text = ''
    NAME="Bloom Nix"
    ID=bloomnix
    VERSION="1.0"
    VERSION_ID="1.0"
    PRETTY_NAME="Bloom Nix 1.0"
    HOME_URL="https://bloom-nix.org/"
    SUPPORT_URL="https://bloom-nix.org/support"
    BUG_REPORT_URL="https://bloom-nix.org/issues"
  '';
  
  # Set the system name
  system.nixos.distroName = "Bloom Nix";
  
  # Replace issue and MOTD
  environment.etc."issue".text = ''
    \e[1;36mBloom Nix\e[0m 1.0 \r (\l)
    
    Welcome to \e[1;36mBloom Nix\e[0m!
  '';
  
  environment.etc."motd".text = ''
    Welcome to Bloom Nix!
    
    For help and information, visit: https://bloom-nix.org
  '';
  
  # Browser homepage and default search
  programs.chromium = {
    enable = true;
    extraOpts = {
      "HomepageLocation" = "https://bloom-nix.org";
      "DefaultSearchProviderEnabled" = true;
      "DefaultSearchProviderName" = "Bloom Nix Search";
      "DefaultSearchProviderSearchURL" = "https://search.bloom-nix.org/?q={searchTerms}";
    };
  };
  
  # KDE customizations
  environment.etc."xdg/plasma-workspace/env/bloom-theme.sh".text = ''
    #!/bin/sh
    export DESKTOP_THEME=breezedark
    export COLOR_SCHEME=BloomNix
    export ICON_THEME=breeze
  '';
  
  # Plymouth boot splash (graphical boot)
  boot.plymouth = {
    enable = true;
    theme = "bloom-nix";
    themePackages = [
      (pkgs.runCommand "bloom-nix-plymouth-theme" {} ''
        mkdir -p $out/share/plymouth/themes/bloom-nix
        
        # Create theme file
        cat > $out/share/plymouth/themes/bloom-nix/bloom-nix.plymouth << EOL
[Plymouth Theme]
Name=Bloom Nix
Description=Bloom Nix Plymouth Theme
ModuleName=script

[script]
ImageDir=$out/share/plymouth/themes/bloom-nix
ScriptFile=$out/share/plymouth/themes/bloom-nix/bloom-nix.script
EOL

        # Create script file
        cat > $out/share/plymouth/themes/bloom-nix/bloom-nix.script << EOL
Window.SetBackgroundTopColor(0.271, 0.302, 0.431);  /* #454d6e */
Window.SetBackgroundBottomColor(0.271, 0.302, 0.431);  /* #454d6e */

logo.image = Image("bloom-logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

progress = 0;

fun refresh_callback() {
  logo.sprite.SetOpacity(Math.Sin(progress / 10) / 2 + 0.5);
  progress++;
}

Plymouth.SetRefreshFunction(refresh_callback);
EOL

        # Create a simple logo if none exists
        cat > $out/share/plymouth/themes/bloom-nix/bloom-logo.png << EOL
# This is a placeholder for the actual logo
EOL
      '')
    ];
  };
  
  # Application menu branding (replace "NixOS" with "Bloom Nix")
  system.activationScripts.bloombrandingApplications = ''
    find /run/current-system/sw/share/applications -name "*.desktop" -type f -exec \
      sed -i 's/NixOS/Bloom Nix/g' {} \;
  '';
  
  # Add custom wallpapers package
  environment.systemPackages = with pkgs; [
    (runCommand "bloom-nix-backgrounds" {} ''
      mkdir -p $out/share/backgrounds/bloom-nix
      mkdir -p $out/share/wallpapers/BloomNix
      
      # Create metadata file for KDE
      cat > $out/share/wallpapers/BloomNix/metadata.desktop << EOL
[Desktop Entry]
Name=Bloom Nix
X-KDE-PluginInfo-Name=BloomNix
X-KDE-PluginInfo-Author=Bloom Nix Team
X-KDE-PluginInfo-Email=contact@bloom-nix.org
X-KDE-PluginInfo-License=GPLv3
EOL
      
      # Create needed directories
      mkdir -p $out/share/wallpapers/BloomNix/contents/images
      
      # Create placeholder
      cat > $out/share/wallpapers/BloomNix/contents/screenshot.jpg << EOL
# This is a placeholder for a screenshot
EOL
    '')
  ];
  
  # Create custom directories
  system.activationScripts.bloombrandingDirs = ''
    mkdir -p /etc/bloom-nix/backgrounds
    mkdir -p /etc/bloom-nix/icons
  '';
}
