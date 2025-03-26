# Base X11 and display manager configuration for Bloom Nix
# Compatible with nixos-23.11
{ config, lib, pkgs, ... }:

{
  # Comprehensive X server and display manager configuration
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

      # Default session - using "plasma" which is the correct name in your environment
      # (The error message told us this is the right name to use)
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
