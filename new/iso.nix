{ config, pkgs, lib, ... }:

{
  imports = [
	# Core NixOS ISO module
	"${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

	# Modules
	./modules/base.nix
	./modules/hardware.nix
	./modules/plasma.nix
  ];

  # ISO metadata
  system.build.isoImage = {
	isoName = "custom-distro.iso";
	volumeID = "CUSTOM_DISTRO";
  };

  # Allow unfree packages for hardware compatibility
  nixpkgs.config.allowUnfree = true;

  # System state version (match your NixOS version)
  system.stateVersion = "23.11";
}
