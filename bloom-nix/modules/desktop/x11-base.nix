# Base X11 and display manager configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Enable X11 with SDDM display manager
  services.xserver = {
    enable = true;

    # Configure display manager
    displayManager = {
      # Use SDDM for KDE Plasma
      sddm.enable = true;

      # Auto-login for the live system
      autoLogin = {
        enable = true;
        user = "nixos";  # Make sure this user exists
      };

      # Default session (used by Plasma)
      defaultSession = "plasma";
    };

    # Enable Plasma desktop environment
    desktopManager.plasma5.enable = true;

    # VM-friendly video drivers
    videoDrivers = [ "qxl" "vmware" "modesetting" "fbdev" ];
  };

  # System-wide Qt integration
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };
}
