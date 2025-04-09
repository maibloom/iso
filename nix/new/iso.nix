{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    # Core NixOS ISO module
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"

    # Modules
    ./modules/base.nix
    ./modules/hardware.nix
    ./modules/plasma.nix
  ];

  # ISO metadata - use the proper option names
  isoImage = {
    isoName = lib.mkForce "bloom.iso";
    volumeID = lib.mkForce "bloom";
  };

  nixpkgs.config.allowBroken = true;

  # Allow unfree packages for hardware compatibility
  nixpkgs.config.allowUnfree = true;

  # System state version (match your NixOS version)
  system.stateVersion = "23.11";
}
