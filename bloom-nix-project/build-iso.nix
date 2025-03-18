# build-iso.nix
{ config, pkgs, lib, ... }:

{
  # allowing unfree apps, so users would be able to download and install apps like vscode and drivers.
  nixpkgs.config.allowUnfree = true;
  
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares.nix>
    ./config/configuration.nix
  ];

  # Override ISO settings
  isoImage = {
    isoName = lib.mkForce "bloom-nix.iso";
    volumeID = lib.mkForce "BLOOM_NIX";
    makeEfiBootable = true;
    makeUsbBootable = true;
    splashImage = lib.mkForce ./branding/splash.png;
  };

  # Force boot settings for ISO
  boot.loader.timeout = lib.mkForce 5;
  # boot.loader.grub.timeout is removed as it's been renamed
  boot.loader.grub.timeoutStyle = lib.mkForce "hidden";

}
