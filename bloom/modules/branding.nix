{ config, lib, pkgs, ... }:

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
 
  # Path to the branding assets directory
  assetsDir = ./branding/assets;
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
  system.nixos.distroName = lib.mkForce "Bloom Nix";
 
  # Make branding images available to the system through environment.etc
  environment.etc = {
    # Logo and icons
    "bloom-nix/logo.png".source = "${assetsDir}/logo.png";
    "bloom-nix/icon.png".source = "${assetsDir}/icon.png";
    "bloom-nix/background.jpg".source = "${assetsDir}/wallpapers/default.jpg";
  };
 
  # Configure GRUB with our branding
  boot.loader.grub = {
    # Enable GRUB explicitly to ensure options like splashImage are recognized
    enable = true;
    
    # Set the splash image after copying it to /boot/grub/splash.png
    splashImage = "/boot/grub/splash.png";
    
    # Set timeout
    timeout = lib.mkForce 5;
    
    # Set background color (used if image fails to load)
    backgroundColor = lib.mkForce colors.primary;
    
    # Enhanced GRUB configuration with corrected color syntax
    extraConfig = ''
      # Set menu colors to match our theme (no spaces around /)
      set menu_color_normal=${colors.secondary + "/" + colors.darkPrimary}
      set menu_color_highlight=${colors.highlight + "/" + colors.secondary}
      
      # Ensure splash is enabled
      splash
       
      # Set timeout style and duration
      set timeout_style=menu
      set timeout=5
    '';
    
    # Optional: Add custom boot entries with corrected paths
    extraEntries = ''
      menuentry "Bloom Nix - Safe Mode" {
        linux /boot/vmlinuz-linux root=LABEL=NIXOS nomodeset
        initrd /boot/initrd.img
      }
    '';
  };
 
  # Copy the custom image to /boot/grub/splash.png
  system.activationScripts.copyGrubImage = {
    text = ''
      mkdir -p /boot/grub
      cp -f ${assetsDir}/grub-background.png /boot/grub/splash.png
    '';
  };
 
  # Configure Plymouth to use the existing "breeze" theme
  boot.plymouth = {
    enable = true;
    theme = lib.mkForce "breeze";
  };
 
  # Export brand colors so they can be used by other modules
  _module.args.bloomColors = colors;
 
  # Export branding assets path so it can be used by other modules
  _module.args.bloomBranding = assetsDir;
 
  # Customize login banner and MOTD
  environment.etc."issue".text = ''
    \e[1;36mBloom Nix\e[0m 1.0 \r (\l)
    
    Welcome to \e[1;36mBloom Nix\e[0m!
  '';
 
  environment.etc."motd".text = ''
    Welcome to Bloom Nix!
    
    For help and information, visit: https://bloom-nix.org
  '';
 
  # Make brand colors available to the theming system
  environment.variables = {
    BLOOM_COLOR_PRIMARY = colors.primary;
    BLOOM_COLOR_SECONDARY = colors.secondary;
    BLOOM_COLOR_ACCENT = colors.accent;
    BLOOM_COLOR_HIGHLIGHT = colors.highlight;
    BLOOM_COLOR_DARK_PRIMARY = colors.darkPrimary;
  };
 
  # Add Bloom Nix wallpapers to standard locations through a package
  environment.systemPackages = with pkgs; [
    (runCommand "bloom-nix-wallpapers" {} ''
      mkdir -p $out/share/backgrounds/bloom-nix
      mkdir -p $out/share/wallpapers
       
      # Copy the wallpaper using cp from the original location
      ln -s ${assetsDir}/wallpapers/default.jpg $out/share/backgrounds/bloom-nix/
      ln -s $out/share/backgrounds/bloom-nix $out/share/wallpapers/bloom-nix
    '')
  ];
}
