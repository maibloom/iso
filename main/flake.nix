{
  description = "Minimal Bloom Nix for testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
    in {
      nixosConfigurations.test-iso = lib.nixosSystem {
        inherit system;
        modules = [
          # ISO image module
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          
          # Basic system configuration
          ({ pkgs, ... }: {
            # Basic ISO settings
            isoImage.edition = "bloom-test";
            isoImage.isoName = "bloom-test.iso";
            isoImage.makeEfiBootable = true;
            isoImage.makeUsbBootable = true;
            
            # Essential packages
            environment.systemPackages = with pkgs; [
              firefox
              git
            ];
            
            # Enable Plasma 6
            services.xserver.enable = true;
            services.xserver.desktopManager.plasma6.enable = true;
            services.xserver.displayManager.sddm.enable = true;
            
            # User configuration
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              initialPassword = "";
            };
            
            # Auto-login for live system
            services.xserver.displayManager.autoLogin = {
              enable = true;
              user = "nixos";
            };
            
            # Allow passwordless sudo
            security.sudo.wheelNeedsPassword = false;
          })
        ];
      };
      
      # Make the ISO available as a package
      packages.${system}.test-iso = self.nixosConfigurations.test-iso.config.system.build.isoImage;
      packages.${system}.default = self.packages.${system}.test-iso;
    };
}
