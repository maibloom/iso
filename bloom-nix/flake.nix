{
  description = "Bloom Nix - A modern NixOS distribution with GNOME";

  inputs = {
    # Core Nix inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager for user configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add other useful inputs
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nix-colors, ... }@inputs:
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
          ./modules/desktop/gnome.nix  # Changed from plasma.nix to gnome.nix
          ./modules/desktop/bloom-theme.nix  # Added the Bloom Theme module
          ./modules/branding/default.nix
          ./modules/packages/default.nix

          # ISO-specific configurations
          ./hosts/iso/default.nix
          
          # Customize ISO properties with priority resolution
          {
            isoImage = {
              edition = "bloom-gnome";
              isoName = "bloom-gnome-${builtins.substring 0 8 self.lastModifiedDate or "19700101"}-${self.shortRev or "dirty"}.iso";
              # Use lib.mkForce to give this definition higher priority
              appendToMenuLabel = lib.mkForce " Bloom Nix GNOME Edition";
            };
          }
        ];
      };

      # Installed system configuration
      nixosConfigurations.desktop = mkNixosConfig {
        modules = [
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/gnome.nix  # Changed from plasma.nix to gnome.nix
          ./modules/desktop/bloom-theme.nix  # Added the Bloom Theme module
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
              echo "Bloom Nix development environment with GNOME"
              echo "Run 'nix build .#iso' to build the ISO"
            '';
          };
        }
      );
    };
}
