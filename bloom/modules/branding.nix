{ config, lib, pkgs, ... }:

let
  # Color palette with proper GRUB color format conversion
  colors = {
    primary = "#454d6e";  # Background
    secondary = "#f1efee"; # Text
    accent = "#999a5e";    # Highlight
    highlight = "#ab6470"; # Selection
    darkPrimary = "#353d5e"; # Alternate background
  };

  # Convert hex to GRUB-compatible RGB values (0-255)
  hexToGrubRGB = hex: let
    r = builtins.parseInt (builtins.substring 1 2 hex) 16;
    g = builtins.parseInt (builtins.substring 3 2 hex) 16;
    b = builtins.parseInt (builtins.substring 5 2 hex) 16;
  in "${toString r},${toString g},${toString b}";
in {
  boot.loader = {
    grub = {
      enable = lib.mkForce true;
      efiSupport = true;
      device = "nodev"; # UEFI systems
      useOSProber = true; # Detect other OSes
      copyKernels = true; # Maintain kernel backups
      fsIdentifier = "uuid";
      configurationName = "Bloom-Nix"; # Unique identifier
      extraEntries = ''
        # Example chainloading entry
        menuentry "Arch Linux" {
          set root=(hd0,gpt2)
          chainloader /EFI/arch/grubx64.efi
        }
      '';
    };
    systemd-boot.enable = lib.mkForce false; # Explicitly disable
    efi.canTouchEfiVariables = true; # Required for UEFI modifications
  };

  boot.loader.grub = {
    extraConfig = ''
      # Color scheme using GRUB's native RGB format
      set color_normal=${hexToGrubRGB colors.accent}/${hexToGrubRGB colors.darkPrimary}
      set color_highlight=${hexToGrubRGB colors.highlight}/${hexToGrubRGB colors.secondary}
      set menu_color_normal=${hexToGrubRGB colors.secondary}/${hexToGrubRGB colors.primary}
      set menu_color_highlight=${hexToGrubRGB colors.highlight}/${hexToGrubRGB colors.secondary}

      # Terminal configuration
      set terminal_output gfxterm
      set terminal_gfxmode=1920x1080,auto
      set gfxpayload=keep
      set timeout_style=menu
      set timeout=5
      set pager=1

      # Custom menu entries
      menuentry "Reboot" { reboot }
      menuentry "Poweroff" { halt }

      # Optional advanced settings
      set menu_color_border=${hexToGrubRGB colors.primary}
      set menu_color_title=${hexToGrubRGB colors.highlight}
      set menu_color_sel=${hexToGrubRGB colors.highlight}/${hexToGrubRGB colors.secondary}
    '';
  };

  system.activationScripts.grubCleanup = {
    text = ''
      # Remove legacy GRUB files
      rm -rf /boot/grub1 /boot/grub.d
      sed -i '/^GRUB_BACKGROUND=/d' /etc/default/grub || true
    '';
  };
}
