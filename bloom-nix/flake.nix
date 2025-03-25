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
    
    # Add other useful inputs
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, plasma-manager, nix-colors, ... }@inputs: 
    let
      lib = nixpkgs.lib;
      
      # System architecture
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
      
      # Function to create a NixOS configuration
      mkNixosConfig = { 
        system ? "x86_64-linux",
        modules ? [] 
      }: lib.nixosSystem {
          inherit system;
          modules = [
            # Include home-manager as a NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { 
                inherit inputs;
                inherit (self) outputs;
              };
            }
          ] ++ modules;  # Properly concatenate the module lists
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
          ./modules/desktop/plasma6.nix
          ./modules/branding/default.nix
          ./modules/packages/default.nix
          
          # ISO-specific configurations
          ./hosts/iso/default.nix

          # Add Calamares modules in the ISO rather than desktop
          ./modules/installer/calamares.nix
          ./modules/installer/calamares-config.nix

        ];
      };
      
      # Installed system configuration
      nixosConfigurations.desktop = mkNixosConfig {
        modules = [
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/plasma6.nix
          ./modules/branding/default.nix
          ./modules/packages/default.nix
          
          # Desktop-specific configurations
          ./hosts/desktop/default.nix

          # Add Calamares modules in the ISO rather than desktop
          ./modules/installer/calamares.nix
          ./modules/installer/calamares-config.nix

        ];
      };
      
      # Make ISO image available as a package
      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      });
      
      # Add devShell for development environment
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