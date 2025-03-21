{
  description = "Bloom Nix - A modern NixOS distribution";

  inputs = {
    # Core Nix inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: 
    let
      lib = nixpkgs.lib;
      
      # System architecture
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
      
      # Helper function to create a NixOS configuration
      mkNixosConfig = { system ? "x86_64-linux", modules ? [] }: 
        lib.nixosSystem {
          inherit system;
          modules = modules;
          specialArgs = { 
            inherit inputs; 
            inherit (self) outputs; 
          };
        };
    in {
      # ISO image configuration
      nixosConfigurations.iso = mkNixosConfig {
        modules = [
          # ISO image creation module from nixpkgs
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/plasma.nix
          ./modules/branding/default.nix
          ./modules/packages/default.nix
          
          # ISO-specific configurations
          ./hosts/iso/default.nix
        ];
      };
      
      # Installed system configuration
      nixosConfigurations.desktop = mkNixosConfig {
        modules = [
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/plasma.nix
          ./modules/branding/default.nix
          ./modules/packages/default.nix
          
          # Desktop-specific configurations
          ./hosts/desktop/default.nix
        ];
      };
      
      # Make ISO image available as a package
      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      });
      
      # Add devShell for development environment (optional)
      devShells = forAllSystems (system: 
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixpkgs-fmt  # Nix formatter
            ];
            shellHook = ''
              echo "Bloom Nix development environment"
              echo "Run 'nix build .#iso' to build the ISO"
            '';
          };
        }
      );
    };
}
