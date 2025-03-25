{
  description = "Bloom Nix - A minimal NixOS-based distribution";

  inputs = {
    # Use the nixos-unstable channel for the latest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      # Define supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Helper function to generate attributes for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Import function to make importing files easier
      importFile = file: import (./. + "/${file}");
      
      # Common modules for both regular system and ISO
      commonModules = [
        ./configuration.nix
        ({ config, pkgs, ... }: {
          # The version of NixOS to base the configuration on
          system.stateVersion = "23.11";
          
          # Basic system identification
          networking.hostName = "bloom-nix";
          
          # Create a default user
          users.users.bloom = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];  # For sudo access
            initialPassword = "bloom";  # Should be changed after first login
          };
          
          # Basic command-line utilities
          environment.systemPackages = with pkgs; [
            vim
            curl
            git
            wget
          ];
          
          # Enable OpenSSH server for remote access
          services.openssh.enable = true;
          
          # No GUI as requested
          services.xserver.enable = false;
        })
      ];
    in {
      # NixOS configurations
      nixosConfigurations = {
        # Default BloomNix configuration
        bloomNix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };  # Pass inputs to modules
          modules = commonModules ++ [
            # Boot configuration for installed system
            ({ ... }: {
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
            })
          ];
        };
        
        # ISO image configuration
        bloomNixISO = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = commonModules ++ [
            # Include the NixOS installation CD module
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            
            # Additional ISO-specific configuration
            ({ config, pkgs, ... }: {
              # Disable unnecessary installation media defaults
              isoImage.squashfsCompression = "gzip -Xcompression-level 1";
              
              # Set a custom ISO name
              isoImage.isoName = "bloom-nix-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
              
              # Add a volume ID that will be used by the boot loader
              isoImage.volumeID = "BLOOM_NIX_ISO";
              
              # Make the installer boot automatically
              boot.loader.timeout = 3;
              
              # Allow the user to log in automatically for the live system
              services.getty.autologinUser = "bloom";
            })
          ];
        };
      };
      
      # Expose the ISO image as a package
      packages = forAllSystems (system: {
        # The ISO image
        iso = self.nixosConfigurations.bloomNixISO.config.system.build.isoImage;
        
        # Set iso as the default package
        default = self.packages.${system}.iso;
      });
    };
}
