# Hardware support configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Enable all firmware
  hardware.enableAllFirmware = true;

  # Enable hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Enable sound with Pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Support for various hardware
  hardware.bluetooth.enable = true;
  hardware.sensor.iio.enable = true;

  # Support for common filesystems
  boot.supportedFilesystems = [ "ntfs" "exfat" "ext4" "btrfs" "xfs" ];

  # Better power management
  powerManagement.enable = true;
  services.thermald.enable = true;

  # Enable CUPS for printing
  services.printing.enable = true;

  # Hardware-specific ISO settings
  # Use mkDefault to allow overriding in other modules
  isoImage.appendToMenuLabel = lib.mkDefault " Live";
}
