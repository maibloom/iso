# Main entry point for building Bloom Nix
# This file creates the ISO image using traditional Nix

{ system ? builtins.currentSystem
, nixpkgs ? <nixpkgs>  # Uses the system's nixpkgs channel
}:

let
  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  lib = pkgs.lib;
  
  # Helper function to import a file with the given dependencies
  importFile = file: import file { inherit pkgs lib; };
  
  # Generate a minimal NixOS ISO image
  nixos = import "${nixpkgs}/nixos" {
    configuration = { config, lib, pkgs, modulesPath, ... }:
    {
      imports = [
        # Include the NixOS minimal ISO module
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        
        # Import our custom modules
        ./modules/base.nix
        ./modules/branding
        ./modules/desktop
        ./modules/hardware
        ./modules/installer
      ];
      
      # ISO image specific configurations
      isoImage = {
        isoName = "bloom-nix.iso";
        volumeID = "BLOOM_NIX";
        makeEfiBootable = true;
        makeUsbBootable = true;
        appendToMenuLabel = " Bloom Nix";
      };
      
      # Make sure unfree packages are allowed (for firmware, etc.)
      nixpkgs.config.allowUnfree = true;
      
      # Default environment variables
      environment.variables = {
        BLOOM_NIX_VERSION = "1.0";
      };
    };
  };
in {
  # The ISO image
  iso = nixos.config.system.build.isoImage;
  
  # Expose the full NixOS evaluation for debugging
  inherit nixos;
}
