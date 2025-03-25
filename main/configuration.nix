# Main configuration.nix file for Bloom Nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    # Hardware scan configuration
    # This will be generated when you install NixOS with nixos-generate-config
    # ./hardware-configuration.nix
  ];
  
  # System configuration options that don't fit in other modules
  # Most configuration should go in dedicated module files
  
  # System-wide environment variables
  environment.variables = {
    EDITOR = "vim";
    BLOOM_NIX_VERSION = "0.1.0";
  };
  
  # Documentation settings
  documentation = {
    enable = true;
    man.enable = true;
    doc.enable = true;
  };
  
  # Localization
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # This is already defined in the flake.nix but could be moved here
  # system.stateVersion = "23.11";
}
