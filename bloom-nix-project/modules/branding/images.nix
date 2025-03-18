# modules/branding/images.nix
{ config, lib, pkgs, ... }:

let
  # Create logo image derivation
  logo = pkgs.runCommand "bloom-nix-logo" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    convert -size 128x128 xc:none \
      -fill "#454d6e" -draw "circle 64,64 64,20" \
      -fill "#f1efee" -gravity center -pointsize 18 -annotate 0 "Bloom\\nNix" \
      $out/logo.png
  '';

  # Create GRUB background derivation
  grubBackground = pkgs.runCommand "bloom-nix-grub-background" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    convert -size 1920x1080 \
      gradient:"#353d5e-#454d6e" \
      -gravity center -pointsize 48 -fill "#f1efee" -annotate 0 "Bloom Nix" \
      $out/grub-background.png
  '';

  # Create Plymouth theme images
  plymouthImages = pkgs.runCommand "bloom-nix-plymouth-images" {
    buildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    
    # Logo for Plymouth
    convert -size 256x256 xc:none \
      -fill "#454d6e" -draw "circle 128,128 128,64" \
      -fill "#f1efee" -gravity center -pointsize 36 -annotate 0 "Bloom\\nNix" \
      $out/logo.png
    
    # Spinner
    convert -size 32x32 xc:none \
      -fill "#f1efee" -draw "circle 16,16 16,4" \
      -alpha set -channel A -evaluate multiply 0.7 \
      -fill none -stroke "#f1efee" -strokewidth 2 \
      -draw "arc 4,4 28,28 0,320" \
      $out/spinner.png
    
    # Progress bar background
    convert -size 400x10 xc:"#353d5e" \
      $out/progress_box.png
    
    # Progress bar foreground
    convert -size 400x10 xc:"#ab6470" \
      $out/progress_bar.png
  '';
in {
  # Make the images available to other modules
  environment.etc."bloom-nix/branding/logo.png".source = "${logo}/logo.png";
  environment.etc."bloom-nix/branding/grub-background.png".source = "${grubBackground}/grub-background.png";

  # Plymouth images
  environment.etc."bloom-nix/plymouth/logo.png".source = "${plymouthImages}/logo.png";
  environment.etc."bloom-nix/plymouth/spinner.png".source = "${plymouthImages}/spinner.png";
  environment.etc."bloom-nix/plymouth/progress_box.png".source = "${plymouthImages}/progress_box.png";
  environment.etc."bloom-nix/plymouth/progress_bar.png".source = "${plymouthImages}/progress_bar.png";
  
  # Update GRUB configuration to use our background
  boot.loader.grub = {
    splashImage = "/etc/bloom-nix/branding/grub-background.png";
  };
  
  # Update Plymouth module to use our images
  boot.plymouth = {
    enable = true;
    themePackages = [
      (pkgs.runCommand "bloom-nix-plymouth-theme" {} ''
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

        # Script file path (the actual script is stored in /etc/bloom-nix/plymouth/)
        mkdir -p $out/etc/bloom-nix/plymouth
        cat > $out/etc/bloom-nix/plymouth/bloom-nix.script << EOF
# Define background color
Window.SetBackgroundTopColor(0.271, 0.302, 0.431);
Window.SetBackgroundBottomColor(0.271, 0.302, 0.431);

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
  t = Plymouth.GetTime();
  opacity = 0.9 + Math.Sin(t * Math.Pi) * 0.1;
  logo.sprite.SetOpacity(opacity);
  
  # Update progress bar
  progress = Plymouth.GetProgress();
  if (progress > 0) {
    new_width = Math.Int(progress_bar.original_image.GetWidth() * progress);
    progress_bar.sprite.SetImage(progress_bar.original_image.Crop(0, 0, new_width, progress_bar.original_image.GetHeight()));
  }
}

Plymouth.SetRefreshFunction(refresh_callback);
EOF

        # Copy the script to the system
        mkdir -p $out/etc/bloom-nix/plymouth
        ln -s /etc/bloom-nix/plymouth/* $out/etc/bloom-nix/plymouth/ || true
      '')
    ];
    theme = "bloom-nix";
  };
}
