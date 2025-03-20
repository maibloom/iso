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

  # Create a derivation for the GRUB theme with robust fallback handling
  grubTheme = pkgs.stdenv.mkDerivation {
    name = "bloom-nix-grub-theme";
    dontUnpack = true;
    
    installPhase = ''
      mkdir -p $out/grub/themes/bloom-nix
      
      # Background image handling with fallbacks
      echo "Finding suitable background image..."
      if [ -f "${brandingDir}/grub-background.png" ]; then
        echo "Using dedicated GRUB background image"
        cp "${brandingDir}/grub-background.png" $out/grub/themes/bloom-nix/background.png
      elif [ -f "${brandingDir}/background.png" ]; then
        echo "Using main background image"
        cp "${brandingDir}/background.png" $out/grub/themes/bloom-nix/background.png
      elif [ -f "${brandingDir}/default.jpg" ]; then
        echo "Converting default.jpg to PNG format for GRUB"
        ${pkgs.imagemagick}/bin/convert "${brandingDir}/default.jpg" $out/grub/themes/bloom-nix/background.png
      else
        echo "No suitable background found, creating a basic gradient"
        ${pkgs.imagemagick}/bin/convert -size 1920x1080 gradient:"#353d5e-#454d6e" $out/grub/themes/bloom-nix/background.png
      fi
      
      # Write the theme content directly from the Nix configuration
      cat > $out/grub/themes/bloom-nix/theme.txt << EOF
${grubThemeContent}
EOF
      
      # Copy any additional theme assets with careful error handling
      if [ -d "${brandingDir}/grub/theme" ]; then
        echo "Copying additional theme assets from ${brandingDir}/grub/theme"
        # Use find instead of shell glob to avoid errors with empty directories
        find "${brandingDir}/grub/theme" -type f -not -name "theme.txt" -exec cp {} $out/grub/themes/bloom-nix/ \;
      else
        echo "No additional theme assets found"
      fi
      
      # Verify we have all required files for the theme
      echo "Verifying theme files..."
      if [ ! -f "$out/grub/themes/bloom-nix/background.png" ]; then
        echo "Warning: background.png is missing, creating a placeholder"
        ${pkgs.imagemagick}/bin/convert -size 1920x1080 xc:#454d6e $out/grub/themes/bloom-nix/background.png
      fi
    '';
  };

  # GRUB early configuration with improved module loading
  isoGrubCfg = pkgs.writeText "grub-early.cfg" ''
    # Load required modules with fallbacks
    echo "Loading graphics modules..."
    insmod all_video || echo "Warning: all_video module failed to load"
    insmod gfxterm || echo "Warning: gfxterm module failed to load"
    insmod png || echo "Warning: png module failed to load"
    insmod gfxmenu || echo "Warning: gfxmenu module failed to load"
    
    # Try multiple graphics modes in case the preferred one fails
    echo "Setting graphics mode..."
    if loadfont ($root)/boot/grub/fonts/unicode.pf2; then
      echo "Loaded Unicode font"
    elif loadfont /boot/grub/fonts/unicode.pf2; then
      echo "Loaded Unicode font from alternate location"
    else
      echo "Warning: Could not load font"
    fi
    
    # Try graphics mode with fallbacks
    set gfxmode=auto
    set gfxpayload=keep
    terminal_output gfxterm
    
    # Set the theme path with comprehensive fallback chain
    echo "Looking for theme file..."
    if [ -e ($root)/boot/grub/themes/bloom-nix/theme.txt ]; then
      echo "Found theme at ($root)/boot/grub/themes/bloom-nix/theme.txt"
      set theme=($root)/boot/grub/themes/bloom-nix/theme.txt
    elif [ -e /boot/grub/themes/bloom-nix/theme.txt ]; then
      echo "Found theme at /boot/grub/themes/bloom-nix/theme.txt"
      set theme=/boot/grub/themes/bloom-nix/theme.txt
    elif [ -e /EFI/boot/grub/themes/bloom-nix/theme.txt ]; then
      echo "Found theme at /EFI/boot/grub/themes/bloom-nix/theme.txt"
      set theme=/EFI/boot/grub/themes/bloom-nix/theme.txt
    elif [ -e /grub/themes/bloom-nix/theme.txt ]; then
      echo "Found theme at /grub/themes/bloom-nix/theme.txt"
      set theme=/grub/themes/bloom-nix/theme.txt
    else
      echo "Warning: Theme not found, using fallback colors"
      set menu_color_normal=white/black
      set menu_color_highlight=black/light-gray
    fi
  '';
in {
  # Configure GRUB with our theme
  boot.loader.grub = {
    # Use our custom theme
    theme = "${grubTheme}/grub/themes/bloom-nix";
    
    # Essential GRUB configuration with improved error handling
    extraConfig = ''
      # Load required modules with fallbacks
      insmod all_video || echo "Warning: all_video module failed to load"
      insmod gfxterm || echo "Warning: gfxterm module failed to load"
      insmod png || echo "Warning: png module failed to load"
      insmod gfxmenu || echo "Warning: gfxmenu module failed to load"
      
      # Set graphics mode with error detection
      if loadfont ($root)/boot/grub/fonts/unicode.pf2; then
        true  # Success, do nothing
      elif loadfont /boot/grub/fonts/unicode.pf2; then
        true  # Success from alternate path
      else
        echo "Warning: Could not load font"
      fi
      
      set gfxmode=auto
      set gfxpayload=keep
      terminal_output gfxterm
      
      # Try multiple theme paths, from most specific to most general
      if [ -e ($root)/boot/grub/themes/bloom-nix/theme.txt ]; then
        set theme=($root)/boot/grub/themes/bloom-nix/theme.txt
      elif [ -e /boot/grub/themes/bloom-nix/theme.txt ]; then
        set theme=/boot/grub/themes/bloom-nix/theme.txt
      elif [ -e /EFI/boot/grub/themes/bloom-nix/theme.txt ]; then
        set theme=/EFI/boot/grub/themes/bloom-nix/theme.txt
      elif [ -e /grub/themes/bloom-nix/theme.txt ]; then
        set theme=/grub/themes/bloom-nix/theme.txt
      else
        echo "Warning: Theme not found, using fallback colors"
        set menu_color_normal=white/black
        set menu_color_highlight=black/light-gray
      fi
    '';
    
    # Install theme to multiple locations with careful error handling
    extraInstallCommands = ''
      echo "Installing GRUB theme to multiple locations..."
      
      # BIOS boot path
      mkdir -p /boot/grub/themes/bloom-nix
      echo "Copying theme to /boot/grub/themes/bloom-nix/"
      cp -r ${grubTheme}/grub/themes/bloom-nix/* /boot/grub/themes/bloom-nix/
      
      # UEFI paths - try multiple locations
      if [ -d /boot/efi ]; then
        echo "Detected UEFI system, installing theme to EFI locations"
        for efi_dir in /boot/efi/EFI/boot /boot/efi/EFI/BOOT /boot/efi/EFI/GRUB; do
          if mkdir -p "$efi_dir/grub/themes/bloom-nix"; then
            echo "Copying theme to $efi_dir/grub/themes/bloom-nix/"
            cp -r ${grubTheme}/grub/themes/bloom-nix/* "$efi_dir/grub/themes/bloom-nix/" || echo "Warning: Failed to copy to $efi_dir"
          fi
        done
      else
        echo "No UEFI partition detected"
      fi
      
      # Verify installation
      echo "Verifying theme installation..."
      for theme_path in /boot/grub/themes/bloom-nix /boot/efi/EFI/boot/grub/themes/bloom-nix; do
        if [ -f "$theme_path/theme.txt" ] && [ -f "$theme_path/background.png" ]; then
          echo "Theme verified at $theme_path"
        elif [ -d "$theme_path" ]; then
          echo "Warning: Incomplete theme at $theme_path"
        fi
      done
    '';
  };
  
  # Configure ISO image GRUB settings with better error handling
  isoImage = {
    # Use our theme for the ISO
    grubTheme = "${grubTheme}/grub/themes/bloom-nix";
    
    # Make bootable on multiple systems
    bootable = true;
    makeEfiBootable = true;
    makeUsbBootable = true;
    
    # Modify the ISO to include our theme with fallback handling
    extraIsoInstallerCommands = ''
      echo "Setting up GRUB theme for ISO..."
      
      # Add early GRUB configuration with fallback detection
      if [ -e ./EFI/boot/grub.cfg ]; then
        echo "Found EFI GRUB config, adding early configuration"
        cp ${isoGrubCfg} ./EFI/boot/grub-early.cfg
        sed -i '1s/^/source \/EFI\/boot\/grub-early.cfg\n/' ./EFI/boot/grub.cfg
      else
        echo "Warning: No EFI GRUB config found"
      fi
      
      # Create theme directories in multiple locations
      for dir in ./boot/grub ./EFI/boot/grub; do
        echo "Creating theme directory at $dir/themes/bloom-nix"
        mkdir -p "$dir/themes/bloom-nix"
        
        echo "Copying theme to $dir/themes/bloom-nix"
        cp -r ${grubTheme}/grub/themes/bloom-nix/* "$dir/themes/bloom-nix/" || echo "Warning: Failed to copy to $dir/themes/bloom-nix"
        
        # Verify copy
        if [ -f "$dir/themes/bloom-nix/theme.txt" ] && [ -f "$dir/themes/bloom-nix/background.png" ]; then
          echo "Theme verified at $dir/themes/bloom-nix"
        else
          echo "Warning: Theme verification failed for $dir/themes/bloom-nix"
        fi
      done
    '';
  };
  
  # Special UEFI boot settings
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  
  # Add a helper script with enhanced error handling
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "fix-grub-theme" ''
      #!/bin/sh
      # This script ensures the GRUB theme is properly installed
      # with comprehensive error handling and diagnostics
      
      LOGFILE="/tmp/fix-grub-theme.log"
      exec > >(tee "$LOGFILE") 2>&1
      
      echo "=== Bloom Nix GRUB Theme Repair Tool ==="
      echo "Started at $(date)"
      echo "Checking for theme files..."
      
      # Check if source theme exists
      if [ ! -d "${grubTheme}/grub/themes/bloom-nix" ]; then
        echo "ERROR: Source theme not found!"
        exit 1
      fi
      
      echo "Source theme found, checking files..."
      if [ ! -f "${grubTheme}/grub/themes/bloom-nix/theme.txt" ]; then
        echo "WARNING: theme.txt is missing from source!"
      fi
      
      if [ ! -f "${grubTheme}/grub/themes/bloom-nix/background.png" ]; then
        echo "WARNING: background.png is missing from source!"
      fi
      
      echo "Installing theme to all possible GRUB locations..."
      SUCCESS=0
      
      # Create theme directories in all known GRUB search paths with careful error handling
      for dir in /boot/grub /boot/grub2 /grub /grub2 /EFI/boot /EFI/BOOT /boot/efi/EFI/boot; do
        echo "Checking $dir..."
        if [ -d "$dir" ] || mkdir -p "$dir"; then
          echo "  Creating $dir/themes/bloom-nix"
          mkdir -p "$dir/themes/bloom-nix"
          
          echo "  Copying theme files"
          if cp -r ${grubTheme}/grub/themes/bloom-nix/* "$dir/themes/bloom-nix/" 2>/dev/null; then
            echo "  ✓ Successfully installed theme to $dir/themes/bloom-nix"
            SUCCESS=1
            
            # Verify critical files
            echo "  Verifying installation..."
            if [ -f "$dir/themes/bloom-nix/theme.txt" ]; then
              echo "    ✓ theme.txt present"
            else
              echo "    ✗ theme.txt missing!"
            fi
            
            if [ -f "$dir/themes/bloom-nix/background.png" ]; then
              echo "    ✓ background.png present"
            else
              echo "    ✗ background.png missing!"
            fi
          else
            echo "  ✗ Failed to copy theme files to $dir/themes/bloom-nix"
          fi
        else
          echo "  ✗ Could not create $dir"
        fi
        echo ""
      done
      
      if [ $SUCCESS -eq 1 ]; then
        echo "Theme installation completed successfully to at least one location."
      else
        echo "ERROR: Failed to install theme to any location!"
      fi
      
      echo "Done at $(date)"
      echo "Log saved to $LOGFILE"
    '')
  ];
}
