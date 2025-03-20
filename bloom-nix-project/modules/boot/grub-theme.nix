# GRUB theme configuration for Bloom Nix
{ config, lib, pkgs, ... }:

let
  # Get branding directory path
  brandingDir = ../../branding;

  # Your custom GRUB theme content embedded directly in the Nix file
  grubThemeContent = ''
    # Bloom Nix GRUB theme

    # Global settings
    title-text: "Welcome to Bloom Nix"
    title-color: "#f1efee"
    message-color: "#f1efee"
    message-bg-color: "#454d6e"
    desktop-color: "#454d6e"
    desktop-image: "background.png"
    terminal-font: "DejaVu Sans Mono Regular 12"

    # Boot menu settings
    + boot_menu {
      left = 15%
      width = 70%
      top = 30%
      height = 40%
      item_color = "#f1efee"
      selected_item_color = "#ab6470"
      item_height = 32
      item_padding = 5
      item_spacing = 10
      icon_width = 32
      icon_height = 32
    }

    # Progress bar
    + progress_bar {
      id = "__timeout__"
      left = 15%
      width = 70%
      top = 75%
      height = 20
      show_text = true
      text_color = "#f1efee"
    }
  '';

  # Create a derivation for the GRUB theme that embeds your theme content
  grubTheme = pkgs.stdenv.mkDerivation {
    name = "bloom-nix-grub-theme";
    dontUnpack = true;
    
    installPhase = ''
      mkdir -p $out/grub/themes/bloom-nix
      
      # Copy background image directly from brandingDir
      cp ${brandingDir}/grub-background.png $out/grub/themes/bloom-nix/background.png
      
      # Write the theme content directly from the Nix configuration
      cat > $out/grub/themes/bloom-nix/theme.txt << EOF
${grubThemeContent}
EOF
      
      # If there are any additional assets in the theme directory, copy them too
      if [ -d "${brandingDir}/grub/theme" ]; then
        for file in ${brandingDir}/grub/theme/*; do
          if [ "$(basename "$file")" != "theme.txt" ]; then
            cp -r "$file" $out/grub/themes/bloom-nix/
          fi
        done
      fi
    '';
  };

  # GRUB early configuration to ensure theme is loaded on physical hardware
  isoGrubCfg = pkgs.writeText "grub-early.cfg" ''
    # Load required modules
    insmod all_video
    insmod gfxterm
    insmod png
    insmod gfxmenu
    
    # Set graphics mode
    set gfxmode=auto
    terminal_output gfxterm
    
    # Set the theme path explicitly for physical hardware boot
    if [ -e /boot/grub/themes/bloom-nix/theme.txt ]; then
      set theme=/boot/grub/themes/bloom-nix/theme.txt
    elif [ -e /EFI/boot/grub/themes/bloom-nix/theme.txt ]; then
      set theme=/EFI/boot/grub/themes/bloom-nix/theme.txt
    fi
    
    # Fallback colors if theme fails to load
    set menu_color_normal=white/black
    set menu_color_highlight=black/light-gray
  '';
in {
  # Configure GRUB with our theme
  boot.loader.grub = {
    # Use our custom theme
    theme = "${grubTheme}/grub/themes/bloom-nix";
    
    # Essential GRUB configuration for graphics
    extraConfig = ''
      # Load required modules
      insmod all_video
      insmod gfxterm
      insmod png
      insmod gfxmenu
      
      # Set graphics mode
      set gfxmode=auto
      terminal_output gfxterm
      
      # Try multiple path formulations to maximize compatibility
      # This helps with physical hardware boot
      if [ -e ($root)/boot/grub/themes/bloom-nix/theme.txt ]; then
        set theme=($root)/boot/grub/themes/bloom-nix/theme.txt
      elif [ -e /boot/grub/themes/bloom-nix/theme.txt ]; then
        set theme=/boot/grub/themes/bloom-nix/theme.txt
      elif [ -e /EFI/boot/grub/themes/bloom-nix/theme.txt ]; then
        set theme=/EFI/boot/grub/themes/bloom-nix/theme.txt
      fi
      
      # Fallback colors if theme fails to load (is disabled)
      # set menu_color_normal=white/black
      # set menu_color_highlight=black/light-gray
    '';
    
    # Install theme to the standard GRUB locations
    extraInstallCommands = ''
      # Create theme directories
      mkdir -p /boot/grub/themes/bloom-nix
      
      # Copy theme files
      cp -r ${grubTheme}/grub/themes/bloom-nix/* /boot/grub/themes/bloom-nix/
      
      # For UEFI booting
      if [ -d /boot/efi ]; then
        mkdir -p /boot/efi/EFI/boot/grub/themes/bloom-nix
        cp -r ${grubTheme}/grub/themes/bloom-nix/* /boot/efi/EFI/boot/grub/themes/bloom-nix/
      fi
    '';
  };
  
  # Configure ISO image GRUB settings
  isoImage = {
    # Use our theme for the ISO
    grubTheme = "${grubTheme}/grub/themes/bloom-nix";
    
    # Make bootable on multiple systems
    bootable = true;
    makeEfiBootable = true;
    makeUsbBootable = true;
    
    # Modify the ISO to include our theme early in boot
    extraIsoInstallerCommands = ''
      # Add early GRUB configuration
      if [ -e ./EFI/boot/grub.cfg ]; then
        cp ${isoGrubCfg} ./EFI/boot/grub-early.cfg
        # Insert it at the beginning of the grub.cfg
        sed -i '1s/^/source \/EFI\/boot\/grub-early.cfg\n/' ./EFI/boot/grub.cfg
      fi
      
      # Create theme directories in the ISO image
      mkdir -p ./boot/grub/themes/bloom-nix
      mkdir -p ./EFI/boot/grub/themes/bloom-nix
      
      # Copy theme files to all locations
      cp -r ${grubTheme}/grub/themes/bloom-nix/* ./boot/grub/themes/bloom-nix/
      cp -r ${grubTheme}/grub/themes/bloom-nix/* ./EFI/boot/grub/themes/bloom-nix/
    '';
  };
  
  # Special UEFI boot settings to ensure theme is accessible on physical hardware
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  
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
}
