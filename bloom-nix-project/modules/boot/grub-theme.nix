# GRUB theme configuration for Bloom Nix
{ config, lib, pkgs, ... }:

let
  # Get branding directory path
  brandingDir = ../../branding;

  # Create a derivation for the GRUB theme
  grubTheme = pkgs.stdenv.mkDerivation {
    name = "bloom-nix-grub-theme";
    
    # No source needed as we're creating the theme directly
    dontUnpack = true;
    
    # Create a complete GRUB theme
    installPhase = ''
      mkdir -p $out/grub/themes/bloom-nix
      
      # Copy background image for GRUB
      cp ${brandingDir}/grub-background.png $out/grub/themes/bloom-nix/background.png
      
      # Copy theme files if they exist
      if [ -d "${brandingDir}/grub/theme" ]; then
        cp -r ${brandingDir}/grub/theme/* $out/grub/themes/bloom-nix/
      fi
      
      # Create a basic theme.txt if it doesn't exist
      if [ ! -f "$out/grub/themes/bloom-nix/theme.txt" ]; then
        cat > $out/grub/themes/bloom-nix/theme.txt << EOF
# Bloom Nix GRUB theme
desktop-image: "background.png"
desktop-color: "#454d6e"
terminal-box: "terminal_box_*.png"
terminal-font: "Unifont Regular 16"

# Boot menu
+ boot_menu {
  left = 15%
  top = 30%
  width = 70%
  height = 40%
  item_font = "Unifont Regular 16"
  item_color = "#f1efee"
  selected_item_color = "#ab6470"
  item_spacing = 1
}

# Countdown timer
+ progress_bar {
  id = "__timeout__"
  left = 15%
  top = 85%
  width = 70%
  height = 16
  show_text = true
  font = "Unifont Regular 14"
  text_color = "#f1efee"
  bar_style = "progress_bar_*.png"
}
EOF
      fi
    '';
  };
in {
  # Configure GRUB to use our theme - ensure this happens early in boot
  boot.loader.grub = {
    # Don't use splash image (use theme instead)
    splashImage = null;
    
    # Set our custom theme
    theme = "${grubTheme}/grub/themes/bloom-nix";
    
    # Essential configuration to make themes work
    extraConfig = ''
      # Set colors for menus without theme 
      set menu_color_normal=white/black
      set menu_color_highlight=black/light-gray
      
      # Force graphical terminal for theme display
      terminal_output gfxterm
      
      # Set the theme explicitly with path resolution that works in both
      # VM and physical hardware environments
      set theme=($root)/boot/grub/themes/bloom-nix/theme.txt
    '';
    
    # Force the theme to be installed properly
    extraInstallCommands = ''
      # Create theme directory in both standard locations
      mkdir -p /boot/grub/themes/bloom-nix
      
      # Copy theme files to the boot directory
      cp -r ${grubTheme}/grub/themes/bloom-nix/* /boot/grub/themes/bloom-nix/
    '';
  };
  
  # Configure ISO image GRUB settings for proper embedding in the image
  isoImage = {
    # Override any existing splash with our theme
    grubTheme = "${grubTheme}/grub/themes/bloom-nix";
  };
  
  # Copy GRUB theme to the EFI directory structure
  # This ensures it's available during early boot
  boot.loader.grub.efiInstallAsRemovable = true;
  
  # Add a helper script to fix GRUB theme issues
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "fix-grub-theme" ''
      #!/bin/sh
      # This script ensures the GRUB theme is properly installed
      # Run this if you're having issues with the GRUB theme
      
      echo "Installing Bloom Nix GRUB theme..."
      
      # Create theme directories in all known GRUB search paths
      for dir in /boot/grub /boot/grub2 /grub /grub2 /EFI/boot /EFI/BOOT /boot/efi/EFI/boot; do
        if [ -d "$dir" ] || mkdir -p "$dir"; then
          mkdir -p "$dir/themes/bloom-nix"
          cp -r ${grubTheme}/grub/themes/bloom-nix/* "$dir/themes/bloom-nix/" || true
          echo "Installed theme to $dir/themes/bloom-nix"
        fi
      done
      
      echo "Theme installation complete!"
    '')
  ];
  
  # Create another activation script to ensure the theme is installed
  system.activationScripts.bloomGrubTheme = {
    text = ''
      # Make sure the GRUB theme is available in the ISO
      mkdir -p /iso/boot/grub/themes/bloom-nix
      cp -r ${grubTheme}/grub/themes/bloom-nix/* /iso/boot/grub/themes/bloom-nix/ 2>/dev/null || true
      
      # Make sure it's also in the EFI directory
      mkdir -p /iso/EFI/boot/grub/themes/bloom-nix
      cp -r ${grubTheme}/grub/themes/bloom-nix/* /iso/EFI/boot/grub/themes/bloom-nix/ 2>/dev/null || true
    '';
    deps = [];
  };
}
