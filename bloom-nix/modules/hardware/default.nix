# Hardware support configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Enable all firmware
  hardware.enableAllFirmware = true;

  hardware.graphics.enable = true;

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

    # Time zone
  time.timeZone = "UTC";

  # Locale and internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
      "de_DE.UTF-8/UTF-8"
      "fr_FR.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
    ];
  };

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

}
