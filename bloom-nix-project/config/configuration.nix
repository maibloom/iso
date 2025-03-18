{ config, pkgs, ... }:

{
  # Import the hardware scan results
  imports = [ ./hardware-configuration.nix ];

  # GRUB bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";  # or "nodev" for EFI systems

  # hostname
  networking.hostName = "bloom-nix";

  # networking
  networking.networkmanager.enable = true;

  # time zone
  time.timeZone = "UTC";

  # system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    pkgs.ungoogled-chromium
  ];

  # Enable SSHD
  services.openssh.enable = true;

  # user account
  users.users.bloom = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "password";
  };

  # State version
  system.stateVersion = "23.11";
}
