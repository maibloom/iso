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
    configuration = { config, lib, pkgs, modulesPath, ... }: {
      imports = [
        # Include the NixOS minimal ISO module
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        ./modules/base.nix
        ./modules/hardware-base.nix
        ./modules/plasma.nix
        ./modules/theme.nix
        ./modules/installer.nix
      ];
      # ...
    };
  };
in {
  # The ISO image
  iso = nixos.config.system.build.isoImage;
 
  # Expose the full NixOS evaluation for debugging
  inherit nixos;
}
