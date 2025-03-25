{
  description = "Minimal ISO configuration with an ISO output alias";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      minimalIso = pkgs.lib.nixosSystem {
        system = system;
        modules = [
          # ISO image creation module from nixpkgs
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          # Essential modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          # VM support (make sure vmSupportModule is defined or imported)
          # vmSupportModule
          # Minimal desktop configuration
          {
            services.xserver.enable = true;
            services.xserver.desktopManager.xfce.enable = true;
            services.xserver.displayManager.lightdm.enable = true;
            services.xserver.displayManager.autoLogin = {
              enable = true;
              user = "nixos";
            };
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" "video" ];
              initialPassword = "";
            };
            security.sudo.wheelNeedsPassword = false;
            environment.systemPackages = with pkgs; [
              firefox
              xfce.xfce4-terminal
              gparted
            ];
            isoImage = {
              edition = "minimal";
              isoName = "bloom-minimal.iso";
              makeEfiBootable = true;
              makeUsbBootable = true;
            };
          }
        ];
      };
    in {
      # Your NixOS configuration output:
      nixosConfigurations = {
        minimal-iso = minimalIso;
      };

      # Expose the ISO image directly as a top-level output:
      iso = minimalIso.config.system.build.isoImage;

      # (Optionally) Also add the ISO under packages and legacyPackages:
      packages = {
        "${system}" = {
          iso = minimalIso.config.system.build.isoImage;
        };
      };
      legacyPackages = {
        "${system}" = {
          iso = minimalIso.config.system.build.isoImage;
        };
      };
    };
}
