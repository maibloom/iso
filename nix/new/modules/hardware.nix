{ config, pkgs, ... }:

{
  # Enable firmware for broad hardware support
  hardware.enableAllFirmware = true;

  # Use the latest kernel for better hardware compatibility
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # OpenGL and graphics support
  hardware.opengl.enable = true;

  # Enable Bluetooth support (optional)
  hardware.bluetooth.enable = true;
}
