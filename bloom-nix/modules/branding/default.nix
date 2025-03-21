# Bloom Nix branding configuration - Flake compatible
{ config, lib, pkgs, inputs, outputs, ... }:

let
  # Brand colors
  colors = {
    primary = "#454d6e";
    secondary = "#f1efee";
    accent = "#999a5e";
    neutral = "#989cad";
    highlight = "#ab6470";
    darkPrimary = "#353d5e";
  };

  # Create a proper derivation with all branding assets
  brandingAssets = pkgs.stdenv.mkDerivation {
    name = "bloom-branding";
    src = ./assets;  # Path to branding assets directory
    
    # Simple installation phase
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
    '';
  };

in {
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
 
  # Make branding images available to the system
  environment.etc = {
    # Logo and icons - using the derivation
    "bloom-nix/logo.png".source = "${brandingAssets}/logo.png";
    
    # Login banner and MOTD
    "issue".text = ''
      \e[1;36mBloom Nix\e[0m 1.0 \r (\l)
       
      Welcome to \e[1;36mBloom Nix\e[0m!
    '';
    
    "motd".text = ''
      Welcome to Bloom Nix!
       
      For help and information, visit: https://bloom-nix.org
    '';
  };
 
  # Configure GRUB with our branding
  boot.loader.grub = {
    splashImage = lib.mkForce "${brandingAssets}/grub-background.png";
    backgroundColor = colors.primary;
    extraConfig = ''
      set menu_color_normal=${colors.secondary}/black
      set menu_color_highlight=${colors.highlight}/${colors.secondary}
      set timeout_style=hidden
    '';
  };
 
  # Export brand colors so they can be used by other modules
  _module.args.bloomColors = colors;
 
  # Export branding assets so they can be used by other modules
  _module.args.bloomBranding = brandingAssets;
 
  # SDDM theme customization
  services.displayManager.sddm.settings = lib.mkIf config.services.displayManager.sddm.enable {
    Theme = {
      Background = "${brandingAssets}/sddm-background.png";
    };
  };
 
  # System branding setup - using the derivation for reliable paths
  system.activationScripts.bloomBrandingSystem = {
    text = ''
      # Make sure all required directories exist
      mkdir -p /usr/share/pixmaps
      mkdir -p /usr/share/icons/hicolor/128x128/apps
      mkdir -p /usr/share/backgrounds/bloom-nix
     
      # Copy logo to standard locations
      cp -f "${brandingAssets}/logo.png" /usr/share/pixmaps/bloom-nix-logo.png || true
      cp -f "${brandingAssets}/logo.png" /usr/share/icons/hicolor/128x128/apps/bloom-nix-logo.png || true
     
      # Set up backgrounds in standard locations
      cp -f "${brandingAssets}/default.jpg" /usr/share/backgrounds/bloom-nix/ || true
    '';
    deps = [];
  };
 
  # Make brand colors available to the theming system
  environment.variables = {
    BLOOM_COLOR_PRIMARY = colors.primary;
    BLOOM_COLOR_SECONDARY = colors.secondary;
    BLOOM_COLOR_ACCENT = colors.accent;
    BLOOM_COLOR_HIGHLIGHT = colors.highlight;
    BLOOM_COLOR_DARK_PRIMARY = colors.darkPrimary;
  };
}
