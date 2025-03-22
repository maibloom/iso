{
  description = "Bloom Nix - A modern NixOS distribution";

  inputs = {
    # Core Nix inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    
    # Home Manager for user configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Plasma Manager for KDE customization
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, plasma-manager, ... }@inputs: 
    let
      lib = nixpkgs.lib;
      
      # System architecture
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
    in {
      # ISO image configuration
      nixosConfigurations.iso = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # ISO image creation module from nixpkgs
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          
          # Include home-manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/plasma.nix
          ./modules/branding/default.nix
          ./modules/packages/default.nix
          
          # ISO-specific configurations
          ./hosts/iso/default.nix
        ];
        specialArgs = { 
          inherit inputs; 
          inherit (self) outputs; 
        };
      };
      
      # Installed system configuration
      nixosConfigurations.desktop = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Include home-manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/plasma.nix
          ./modules/branding/default.nix
          ./modules/packages/default.nix
          
          # Desktop-specific configurations
          ./hosts/desktop/default.nix
        ];
        specialArgs = { 
          inherit inputs; 
          inherit (self) outputs; 
        };
      };
      
      # Make ISO image available as a package
      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      });
    };
}
