{ config, lib, pkgs, bloomColors ? {}, bloomBranding ? null, ... }:

let
  # Use branding colors if provided, otherwise fallback to defaults
  colors = if bloomColors != {} then bloomColors else {
    primary = "#454d6e";
    secondary = "#f1efee";
    accent = "#999a5e";
    neutral = "#989cad";
    highlight = "#ab6470";
    darkPrimary = "#353d5e";
  };

  # Use branding assets if provided, otherwise create our own derivation
  brandingAssets = if bloomBranding != null then bloomBranding else pkgs.stdenv.mkDerivation {
    name = "plymouth-branding";
    src = ../../../branding;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
    '';
  };

  # Create Plymouth theme
  plymouthTheme = pkgs.runCommand "bloom-nix-plymouth-theme" {} ''
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
  '';
in {
  # Make Plymouth script available to the system
  environment.etc."bloom-nix/plymouth/bloom-nix.script".text = ''
    # Define background color - Bloom Nix primary color
    Window.SetBackgroundTopColor(0.271, 0.302, 0.431);  /* ${colors.primary} */
    Window.SetBackgroundBottomColor(0.271, 0.302, 0.431);  /* ${colors.primary} */
    
    # Load logo image
    logo.image = Image("logo.png");
    logo.sprite = Sprite(logo.image);
    logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
    logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 40);
    
    # Create spinner
    spinner_image = Image("${brandingAssets}/logo.png");
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

  # Configure Plymouth with our theme
  boot.plymouth = {
    enable = true;
    theme = "bloom-nix";
    themePackages = [ plymouthTheme ];
  };
 
  # Set proper kernel parameters for Plymouth
  boot.kernelParams = [
    "quiet"     # Reduce kernel output
    "splash"    # Enable splash screen
    "rd.systemd.show_status=false"  # Hide systemd messages
    "rd.udev.log_level=3"           # Reduce udev logging
    "udev.log_priority=3"           # More udev log reduction
    "vt.global_cursor_default=0"    # Hide cursor
  ];
}
