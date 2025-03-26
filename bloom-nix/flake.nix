{
  description = "Bloom Nix - A customized NixOS distribution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in {
      packages.${system} = {
        iso = self.nixosConfigurations.bloomNixISO.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      };
      
      nixosConfigurations.bloomNixISO = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./modules/desktop/x11-base.nix
          ./modules/hardware/default.nix
          ./modules/branding/default.nix
          ./modules/desktop/plasma6.nix
          ./modules/packages/default.nix
          ./modules/installer/default.nix
          
          # Basic configuration
          ({ config, pkgs, lib, ... }: {
            nixpkgs.config.allowUnfree = true;
            
            # System identity
            system.nixos.distroName = lib.mkForce "Bloom Nix";
            
            # ISO configuration  
            isoImage = {
              isoName = lib.mkForce "bloom-nix.iso";
              volumeID = lib.mkForce "BLOOM_NIX";
              makeEfiBootable = true;
              makeUsbBootable = true;
            };
          })
        ];
      };
    };
}
