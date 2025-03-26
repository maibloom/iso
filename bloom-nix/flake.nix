{
  description = "Bloom Nix - A customized NixOS distribution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in {
      packages.${system}.default = nixos-generators.nixosGenerate {
        system = system;
        format = "iso";
        modules = [
          # Your core system configuration
          ./base-module.nix
          
          # Desktop environment (KDE Plasma)
          ./modules/desktop/plasma.nix
          
          # Bloom Nix branding
          ./modules/branding/default.nix
          
          # Hardware support
          ./modules/hardware/default.nix
          
          # Custom packages
          ./modules/packages/default.nix
          
          # Installer configuration (Calamares)
          ./modules/installer/calamares.nix
          
          # Final customizations and overrides
          ({ config, pkgs, ... }: {
            # Allow non-free firmware
            nixpkgs.config.allowUnfree = true;
            
            # System identity
            system.nixos.distroName = "Bloom Nix";
            networking.hostName = "bloom-nix";
            
            # ISO-specific settings that need to override defaults
            isoImage = {
              edition = "plasma";
              compressImage = true;
              volumeID = "BLOOM_NIX";
              isoName = "bloom-nix.iso";
            };
          })
        ];
      };
    };
}
