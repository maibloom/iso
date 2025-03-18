# modules/branding/default.nix
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

  # Generate logo image (simple circle without text)
  logoImage = pkgs.runCommand "bloom-nix-logo" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    # Create a simple logo - no text, just shapes
    convert -size 128x128 xc:none \
      -fill "${colors.primary}" -draw "circle 64,64 64,20" \
      -fill "${colors.highlight}" -draw "circle 64,64 20,64" \
      $out/logo.png
  '';

  # Generate GRUB background - just a gradient, no text
  grubBackground = pkgs.runCommand "bloom-nix-grub-background" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    convert -size 1920x1080 \
      gradient:"${colors.darkPrimary}-${colors.primary}" \
      $out/grub-background.png
  '';

  # Generate Plymouth theme images - simple shapes, no text
  plymouthImages = pkgs.runCommand "bloom-nix-plymouth-images" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    
    # Logo for Plymouth - simple circle
    convert -size 256x256 xc:none \
      -fill "${colors.primary}" -draw "circle 128,128 128,64" \
      -fill "${colors.highlight}" -draw "circle 128,128 64,128" \
      $out/logo.png
    
    # Spinner - simple ring
    convert -size 32x32 xc:none \
      -fill "none" -stroke "${colors.secondary}" -strokewidth 2 \
      -draw "circle 16,16 16,4" \
      -draw "arc 4,4 28,28 0,320" \
      $out/spinner.png
    
    # Progress bar background
    convert -size 400x10 xc:"${colors.darkPrimary}" \
      $out/progress_box.png
    
    # Progress bar foreground
    convert -size 400x10 xc:"${colors.highlight}" \
      $out/progress_bar.png
  '';

  # Create Plymouth theme
  plymouthTheme = pkgs.runCommand "bloom-nix-plymouth-theme" {
    buildInputs = [ ];
  } ''
    mkdir -p $out/share/plymouth/themes/bloom-nix
    
    # Theme file
    cat > $out/share/plymouth/themes/bloom-nix/bloom-nix.plymouth << EOF
[Plymouth Theme]
Name=Bloom Nix
Description=Bloom Nix Branded Boot Theme
ModuleName=script

[script]
ImageDir=/etc/bloom-nix/plymouth
ScriptFile=/etc/bloom-nix/plymouth/bloom-nix.script
EOF
    
    # Link images
    ln -s ${plymouthImages}/logo.png $out/share/plymouth/themes/bloom-nix/
    ln -s ${plymouthImages}/spinner.png $out/share/plymouth/themes/bloom-nix/
    ln -s ${plymouthImages}/progress_box.png $out/share/plymouth/themes/bloom-nix/
    ln -s ${plymouthImages}/progress_bar.png $out/share/plymouth/themes/bloom-nix/
  '';
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
    # Logo
    "bloom-nix/logo.png".source = "${logoImage}/logo.png";
    
    # GRUB background
    "bloom-nix/grub-background.png".source = "${grubBackground}/grub-background.png";
    
    # Plymouth images and script
    "bloom-nix/plymouth/logo.png".source = "${plymouthImages}/logo.png";
    "bloom-nix/plymouth/spinner.png".source = "${plymouthImages}/spinner.png";
    "bloom-nix/plymouth/progress_box.png".source = "${plymouthImages}/progress_box.png";
    "bloom-nix/plymouth/progress_bar.png".source = "${plymouthImages}/progress_bar.png";
    
    # Plymouth script
    "bloom-nix/plymouth/bloom-nix.script".text = ''
# Define background color - Bloom Nix primary color
Window.SetBackgroundTopColor(0.271, 0.302, 0.431);  /* ${colors.primary} */
Window.SetBackgroundBottomColor(0.271, 0.302, 0.431);  /* ${colors.primary} */

# Load logo image
logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 40);

# Create spinner
spinner_image = Image("spinner.png");
spinner_sprite = Sprite();
spinner_sprite.SetImage(spinner_image);
spinner_sprite.SetX(Window.GetWidth() / 2 - spinner_image.GetWidth() / 2);
spinner_sprite.SetY(Window.GetHeight() / 2 + logo.image.GetHeight() / 2 + 50);

# Add progress bar
progress_bar.original_image = Image("progress_bar.png");
progress_bar.sprite = Sprite();
progress_bar.sprite.SetPosition(Window.GetWidth() / 2 - progress_bar.original_image.GetWidth() / 2, Window.GetHeight() / 2 + logo.image.GetHeight() / 2 + 50);

progress_box.image = Image("progress_box.png");
progress_box.sprite = Sprite(progress_box.image);
progress_box.sprite.SetPosition(Window.GetWidth() / 2 - progress_box.image.GetWidth() / 2, Window.GetHeight() / 2 + logo.image.GetHeight() / 2 + 50);

# Spinner animation
spinner_angle = 0;
fun refresh_callback() {
  # Rotate spinner
  spinner_angle = Math.Mod(spinner_angle + 1, 360);
  spinner_sprite.SetImage(spinner_image.Rotate(spinner_angle));
  
  # Animate logo with subtle pulsing
  if (Plymouth.GetMode() == "boot") {
    t = Plymouth.GetTime();
    opacity = 0.9 + Math.Sin(t * Math.Pi) * 0.1;
    logo.sprite.SetOpacity(opacity);
  }
  
  # Update progress bar if plymouth sends progress updates
  if (Plymouth.GetMode() == "boot") {
    progress = Plymouth.GetProgress();
    if (progress > 0) {
      new_width = Math.Int(progress_bar.original_image.GetWidth() * progress);
      progress_bar.sprite.SetImage(progress_bar.original_image.Crop(0, 0, new_width, progress_bar.original_image.GetHeight()));
    }
  }
}

Plymouth.SetRefreshFunction(refresh_callback);
    '';
    
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
    splashImage = lib.mkForce "/etc/bloom-nix/grub-background.png";
    backgroundColor = colors.primary;
    extraConfig = ''
      set menu_color_normal=${colors.secondary}/black
      set menu_color_highlight=${colors.highlight}/${colors.secondary}
      set timeout_style=hidden
    '';
  };
  
  # Configure Plymouth with our theme
  boot.plymouth = {
    enable = true;
    theme = "bloom-nix";
    themePackages = [ plymouthTheme ];
  };
  
  # Set proper kernel parameters for Plymouth
  boot.kernelParams = [
    "quiet"  # Reduce kernel output
    "splash"  # Enable splash screen
    "rd.systemd.show_status=false"  # Hide systemd messages
    "rd.udev.log_level=3"  # Reduce udev logging
    "udev.log_priority=3"  # More udev log reduction
    "vt.global_cursor_default=0"  # Hide cursor
  ];
  
  # System branding for XFCE
  system.activationScripts.bloombrandingSystem = ''
    # Copy branding elements to standard locations
    mkdir -p /usr/share/pixmaps
    mkdir -p /usr/share/icons/hicolor/128x128/apps
    
    # Copy logo to standard locations
    cp -f /etc/bloom-nix/logo.png /usr/share/pixmaps/bloom-nix-logo.png || true
    cp -f /etc/bloom-nix/logo.png /usr/share/icons/hicolor/128x128/apps/bloom-nix-logo.png || true
    
    # Create a symlink for the desktop background
    mkdir -p /usr/share/backgrounds/bloom-nix
    ln -sf /etc/bloom-nix/grub-background.png /usr/share/backgrounds/bloom-nix/default.jpg || true
  '';
}
