{
  description = "Bloom Nix - A minimal NixOS-based distribution";

  inputs = {
    # Use the nixos-unstable channel for the latest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # You can add more inputs here as needed
    # Example: home-manager for user environment management
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      # Define supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Helper function to generate attributes for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Import function to make importing files easier
      # This allows importing Nix files relative to the flake root
      importFile = file: import (./. + "/${file}");
    in {
      # NixOS configurations
      nixosConfigurations = {
        # Default BloomNix configuration
        bloomNix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };  # Pass inputs to modules
          modules = [
            # Main configuration file
            ./configuration.nix
            
            # You can import additional module files as needed
            # ./modules/base.nix
            # ./modules/users.nix
            # ./modules/networking.nix
            
            # Inline configuration (can be moved to separate files later)
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
              
              # Boot configuration
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
              
              # No GUI as requested
              services.xserver.enable = false;
            })
          ];
        };
      };
      
      # Custom packages specific to Bloom Nix
      # These can be defined in separate files under ./packages/
      packages = forAllSystems (system: 
        let 
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          # Example of a custom package (uncomment and implement when needed)
          # bloom-utils = pkgs.callPackage ./packages/bloom-utils { };
        }
      );
      
      # NixOS modules that can be shared and imported in configurations
      nixosModules = {
        # Define reusable modules (uncomment and implement when needed)
        # bloom-base = import ./modules/bloom-base.nix;
      };
    };
}
