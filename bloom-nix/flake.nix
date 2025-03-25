{
  description = "Bloom Nix - A minimal NixOS-based distribution";

  inputs = {
    # Use a specific stable version for better compatibility
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # Helper function to create the ISO configuration
      mkIsoConfiguration = { modules ? [] }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Include the minimal CD installation module
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          
          # Override conflicting options (at highest priority)
          ({ lib, ... }: {
            # These settings will take highest priority
            isoImage = {
              isoName = lib.mkForce "bloom-nix.iso";
              volumeID = lib.mkForce "BLOOM_NIX";
              makeEfiBootable = lib.mkForce true;
              makeUsbBootable = lib.mkForce true;
              appendToMenuLabel = lib.mkForce " Bloom Nix";
              # Override compression
              squashfsCompression = lib.mkForce "gzip -Xcompression-level 1";
            };
            
            # Use overlayFS for the live system
            boot.initrd.supportedFilesystems = lib.mkForce [ "overlay" ];
          })
          
          # Import the base configuration module the user shared
          ./base-module.nix
          
          # Add additional configuration
          ({ config, lib, pkgs, ... }: {
            # Create a default user with auto-login for the live system
            users.users.bloom = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialPassword = "bloom";
            };
            services.getty.autologinUser = lib.mkForce "bloom";
            
            # Use a stable kernel for better compatibility
            boot.kernelPackages = pkgs.linuxPackages;
            
            # Boot with conservative parameters for better compatibility
            boot.kernelParams = [ 
              "nomodeset" 
              "boot.shell_on_fail" 
              "debug"
              "loglevel=7"
            ];
            
            # Minimal dummy filesystem configuration to satisfy requirements
            fileSystems = lib.mkForce {
              "/" = {
                device = "/dev/disk/by-label/nixos";
                fsType = "ext4";
              };
            };
            
            # Disable documentation to reduce complexity
            documentation.enable = lib.mkForce false;
            documentation.man.enable = lib.mkForce false;
            documentation.doc.enable = lib.mkForce false;
            documentation.info.enable = lib.mkForce false;
          })
        ] ++ modules;
      };
    in {
      # NixOS ISO configuration
      nixosConfigurations.bloomNixISO = mkIsoConfiguration {
        modules = [];  # You can add additional modules here if needed
      };
      
      # Expose the ISO image as a package
      packages.${system} = {
        # Build the ISO directly
        iso = self.nixosConfigurations.bloomNixISO.config.system.build.isoImage;
        
        # Set default package
        default = self.packages.${system}.iso;
      };
    };
}
