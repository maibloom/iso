# modules/installer/default.nix
# This file imports all installer modules

{ config, lib, pkgs, ... }:

{
  # Import the Calamares modules
  imports = [
    ./calamares.nix
    ./calamares-config.nix
  ];
}
