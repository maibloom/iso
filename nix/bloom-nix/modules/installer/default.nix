{ config, lib, pkgs, ... }:

{
  # Import the Calamares modules
  imports = [
    ./calamares.nix
    ./calamares-config.nix
  ];
}
