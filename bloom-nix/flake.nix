{
  description = "Bloom Nix";

  inputs = {
    # Core Nix inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Hardware support
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    
    # For user configurations (can be added later)
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: 
    let
      lib = nixpkgs.lib;
      
      # System architecture - can be expanded for other architectures
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
      
      # Function to create a NixOS configuration
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
          # ISO image creation module
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          
          # Bloom Nix modules
          ./modules/base
          ./modules/hardware
          ./modules/desktop/plasma.nix
          ./modules/branding
          
          # ISO-specific configurations
          ./hosts/iso
        ];
      };
      
      # Installed system configuration
      nixosConfigurations.desktop = mkNixosConfig {
        modules = [
          # Bloom Nix modules
          ./modules/base
          ./modules/hardware
          ./modules/desktop/plasma.nix
          ./modules/branding
          
          # Desktop-specific configurations
          ./hosts/desktop
        ];
      };
      
      # Make ISO image available as a package
      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      });
      
      # For automation and CI/CD
      checks = forAllSystems (system: {
        # Add checks here if needed
      });
    };
}
