{
  description = "Bloom Nix - A minimal NixOS distribution with Plasma 6";

  inputs = {
    # Core Nix inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager for user configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
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
     
      # Minimal VM support module
      vmSupportModule = { config, lib, pkgs, ... }: {
        # Enable necessary kernel modules for VMs
        boot.initrd.availableKernelModules = [
          "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk"
        ];
     
        # Optimize kernel parameters for VMs
        boot.kernelParams = [ "nomodeset" "ibt=off" ];
     
        # Enable firmware that might be needed
        hardware.enableRedistributableFirmware = true;
     
        # SPICE agent for better mouse, clipboard, and resolution handling
        services.spice-vdagentd.enable = true;
     
        # Add VM-related packages
        environment.systemPackages = with pkgs; [
          spice-vdagent
        ];
      };
    in {
      # ISO image configuration
      nixosConfigurations.iso = mkNixosConfig {
        modules = [
          # ISO image creation module from nixpkgs
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

          # Bloom Nix modules - using the minimal required set
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/plasma6.nix     # Our minimal Plasma 6 module
          ./modules/packages/default.nix

          # ISO-specific configurations
          ./hosts/iso/default.nix
         
          # Add VM support module
          vmSupportModule
          
          # Add Calamares modules in the ISO rather than desktop
          ./modules/installer/calamares.nix
          ./modules/installer/calamares-config.nix
         
          # Customize ISO properties
          {
            isoImage = {
              edition = "bloom-plasma6";
              isoName = "bloom-plasma6-${builtins.substring 0 8 self.lastModifiedDate or "19700101"}-${self.shortRev or "dirty"}.iso";
              appendToMenuLabel = lib.mkForce " Bloom Nix Plasma 6";
              makeEfiBootable = true;
              makeUsbBootable = true;
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
          ./modules/desktop/plasma6.nix     # Our minimal Plasma 6 module
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
              nixpkgs-fmt
            ];
            shellHook = ''
              echo "Bloom Nix development environment with Plasma 6"
              echo "Run 'nix build .#iso' to build the ISO"
            '';
          };
        }
      );
    };
}
