{
  description = "A minimal NixOS ISO configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # or your desired branch

  outputs = { self, nixpkgs }: {
    nixosConfigurations.minimal-iso = nixpkgs.lib.nixos.mkNixosConfig {
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
        ./modules/base/default.nix
        ./modules/hardware/default.nix
        vmSupportModule
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
  };
}
