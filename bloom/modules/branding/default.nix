# Branding configuration for Bloom Nix - Appearance and identity
{ config, lib, pkgs, ... }:

let
  # Define brand colors
  bloomColors = {
    primary = "#FF5F15";    # Orange primary color
    secondary = "#3C0061";  # Purple secondary color
    background = "#000000"; # Black background
    text = "#FFFFFF";       # White text
  };
  
  # Create a package containing all branding assets
  brandingAssets = pkgs.stdenvNoCC.mkDerivation {
    name = "bloom-nix-branding";
    
    # No source needed, we'll create/install files during build
    dontUnpack = true;
    
    # Copy all assets from the assets directory
    installPhase = ''
      mkdir -p $out/share/bloom-nix
      
      # Copy assets from the project directory
      cp -r ${./assets}/* $out/share/bloom-nix/
      
      # Create symbolic links for easy access
      mkdir -p $out/share/pixmaps
      ln -s $out/share/bloom-nix/logo.png $out/share/pixmaps/bloom-nix-logo.png
      
      # Create plymouth theme directory
      mkdir -p $out/share/plymouth/themes/bloom-nix
      cp $out/share/bloom-nix/plymouth/* $out/share/plymouth/themes/bloom-nix/
    '';
  };
in
{
  # Replace the operating system identity
  system.nixos.distroName = "Bloom Nix";
  system.nixos.distroVersion = "1.0";
  
  # Set custom /etc/os-release
  environment.etc."os-release".text = ''
    NAME="Bloom Nix"
    ID=bloomnix
    VERSION="1.0"
    VERSION_ID="1.0"
    PRETTY_NAME="Bloom Nix 1.0"
    HOME_URL="https://bloom-nix.org/"
    SUPPORT_URL="https://bloom-nix.org/support"
    BUG_REPORT_URL="https://bloom-nix.org/issues"
    LOGO=bloom-nix-logo
  '';
  
  # Set custom issue file (login prompt)
  environment.etc."issue".text = ''
    \e[1;38;2;255;95;21mBloom Nix\e[0m 1.0 \r (\l)
    
    Welcome to \e[1;38;2;255;95;21mBloom Nix\e[0m!
  '';
  
  # Set custom motd (message of the day)
  environment.etc."motd".text = ''
    Welcome to Bloom Nix!
    
    For help and information, visit: https://bloom-nix.org
  '';
  
  # Configure GRUB with our branding
  boot.loader.grub = {
    splashImage = "${brandingAssets}/share/bloom-nix/grub-background.png";
    backgroundColor = bloomColors.background;
    extraConfig = ''
      set menu_color_normal=${bloomColors.text}/${bloomColors.background}
      set menu_color_highlight=${bloomColors.primary}/${bloomColors.secondary}
      set timeout_style=hidden
    '';
  };
  
  # Configure Plymouth boot splash
  boot.plymouth = {
    enable = true;
    theme = "bloom-nix";
    themePackages = [ brandingAssets ];
  };
  
  # Make the branding assets available system-wide
  environment.systemPackages = [ brandingAssets ];
  
  # Set environment variables for brand colors
  environment.variables = {
    BLOOM_COLOR_PRIMARY = bloomColors.primary;
    BLOOM_COLOR_SECONDARY = bloomColors.secondary;
    BLOOM_COLOR_BACKGROUND = bloomColors.background;
    BLOOM_COLOR_TEXT = bloomColors.text;
  };
  
  # Export brand colors for other modules
  _module.args.bloomColors = bloomColors;
  _module.args.brandingAssets = brandingAssets;
}
