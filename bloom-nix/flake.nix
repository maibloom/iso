{
  description = "Bloom Nix - A minimal NixOS-based distribution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs, ... }: 
    let
      system = "x86_64-linux";
    in {
      # ISO configuration
      nixosConfigurations.bloomNixISO = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Include the NixOS installation CD module
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          
          ./modules/hardware/default.nix
          ./modules/branding/default.nix
          ./modules/desktop/plasma6.nix
          ./modules/packages/default.nix
          ./hosts/iso/default.nix
          ./modules/installer/default.nix

          # Our custom configuration
          ({ config, lib, pkgs, ... }: {
            # System identity
            system.nixos.distroName = lib.mkForce "Bloom Nix";
            networking.hostName = "bloom-nix";
            
            # The ISO image settings
            isoImage = {
              isoName = lib.mkForce "bloom-nix.iso";
              volumeID = lib.mkForce "BLOOM_NIX";
              makeEfiBootable = true;
              makeUsbBootable = true;
              appendToMenuLabel = " Bloom Nix";
              squashfsCompression = lib.mkForce "gzip -Xcompression-level 1";
            };
            
            # Create a default user
            users.users.bloom = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialPassword = "bloom";
            };
            services.getty.autologinUser = lib.mkForce "bloom";
            
            # Basic packages
            environment.systemPackages = with pkgs; [
              vim nano wget curl git htop
              zip unzip file tree rsync
            ];
            
            # CRITICAL FIX: Disable wireless networking to prevent conflicts
            networking.wireless.enable = lib.mkForce false;
            
            # Continue to use NetworkManager
            networking.networkmanager.enable = true;
            
            # Boot configuration
            boot.kernelPackages = pkgs.linuxPackages;
            boot.kernelParams = [ "nomodeset" "boot.shell_on_fail" ];
            
            # State version
            system.stateVersion = "23.11";
          
          
          
          })
        ];
      };
      
      # Define packages
      packages.${system} = {
        iso = self.nixosConfigurations.bloomNixISO.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      };
    };
}
