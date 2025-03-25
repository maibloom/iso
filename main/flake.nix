{
  description = "My minimal ISO configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        "minimal-iso" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # ISO image creation module from nixpkgs
            "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

            # Essential modules
            ./modules/base/default.nix
            ./modules/hardware/default.nix

            # VM support (ensure vmSupportModule is defined or imported)
            vmSupportModule

            # Minimal desktop configuration
            {
              services.xserver.enable = true;

              # Lightweight desktop environment: XFCE
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.displayManager.lightdm.enable = true;

              # Auto-login settings
              services.xserver.displayManager.autoLogin = {
                enable = true;
                user = "nixos";
              };

              # User configuration
              users.users.nixos = {
                isNormalUser = true;
                extraGroups = [ "wheel" "networkmanager" "video" ];
                initialPassword = "";
              };

              # Sudo settings
              security.sudo.wheelNeedsPassword = false;

              # Basic packages
              environment.systemPackages = with nixpkgs.pkgs; [
                firefox
                xfce.xfce4-terminal
                gparted
              ];

              # ISO image settings
              isoImage = {
                edition = "minimal";
                isoName = "bloom-minimal.iso";
                makeEfiBootable = true;
                makeUsbBootable = true;
              };
            }
          ];
        };
      };
    };
}



