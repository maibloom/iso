{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    ./config/configuration.nix
  ];
  
  isoImage.isoName = "bloom-nix.iso";
  isoImage.volumeID = "BLOOM_NIX";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
}
