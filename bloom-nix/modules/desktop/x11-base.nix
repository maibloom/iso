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

      # Auto-login for the live system - this is the ONLY place
      # where auto-login should be configured
      autoLogin = {
        enable = true;
        user = "nixos";  # Make sure this user exists
      };

      # Default session (used by Plasma)
      defaultSession = "plasma5";
    };

    # Enable Plasma desktop environment
    # In nixos-23.11, it's called "plasma5" not "plasma"
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
