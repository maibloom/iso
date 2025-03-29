{ config, lib, pkgs, ... }:

{
  # Base Calamares configuration
  services.calamares = {
    enable = true;
    branding = {
      bloom = {
        componentName = "bloom";
        strings = {
          productName = "Bloom Nix GNU/Linux";
          shortProductName = "Bloom Nix";
        };
        style = {
          sidebarBackground = "#2d2d2d";
          sidebarText = "#ffffff";
        };
        images = {
          productLogo = lib.mkForce null; # Remove logo
        };
      };
    };
  };

  # Special NixOS integration
  services.calamares.modules = {
    nixos = {
      configuration = {
        nixpkgs = {
          overlays = [];
          config = { allowUnfree = true; };
        };
      };
    };
  };
}
