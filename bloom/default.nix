{ nixpkgs ? <nixpkgs>,  # ✅ Required
  modulesDir ? toString ./modules
}:

let
  pkgs = import nixpkgs { 
    config = {
      allowUnfree = true;
      calamares.branding = "bloom";
    };
  };

  nixos = import "${nixpkgs}/nixos" {
    configuration = { config, lib, pkgs, modulesPath, ... }: {
      imports = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma5.nix"
        "${modulesDir}/calamares-config.nix"
        "${modulesDir}/base.nix"
        "${modulesDir}/branding.nix"
        "${modulesDir}/hardware-base.nix"
        "${modulesDir}/plasma.nix"
      ];

      # Critical fixes
      services.calamares = {
        enable = true;
        configFile = ./modules/calamares-config.nix;
      };

      users.users.nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
      };

      services.xserver.displayManager.autoLogin = {
        user = "nixos";  # ✅ Match user definition
        enable = true;
      };
    };
  };
in {
  iso = nixos.config.system.build.isoImage;
}
