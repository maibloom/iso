{ config, pkgs, ... }:

let
  simpleGrubTheme = pkgs.stdenv.mkDerivation {
    name = "simple-grub-theme";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/grub/themes/simple
      # Copy a background image from the project’s branding folder.
      cp ${./branding/grub/background.png} $out/grub/themes/simple/background.png
      # Write a minimal theme file that sets the desktop image.
      cat > $out/grub/themes/simple/theme.txt <<EOF
# Simple GRUB Theme
desktop-image: "background.png"
EOF
    '';
  };
in {
  boot.loader.grub = {
    # Point GRUB’s theme option to the generated theme directory.
    theme = "${simpleGrubTheme}/grub/themes/simple";
  };
}
