# SDDM configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Apply SDDM theme settings only if SDDM is enabled
  config = lib.mkIf (config.services.xserver.enable && 
                     config.services.displayManager.sddm.enable) {
    services.displayManager.sddm.settings = {
      Theme = {
        # Use the background defined in the branding module
        Background = config.bloom.sddmBackground;
      };
    };
  };
}
