# Configuration for installed Bloom Nix systems
{ config, pkgs, lib, ... }:

{
  # Boot loader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";  # Install to EFI system partition
  };
  
  # Enable filesystem support for common formats
  boot.supportedFilesystems = [ "ntfs" "vfat" "exfat" "ext4" "btrfs" "xfs" ];

  # Default user configuration (modify during installation)
  users.users.bloom = {
    isNormalUser = true;
    description = "Bloom Nix User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "bloom";  # Should be changed during first login
  };

  # Additional desktop applications
  environment.systemPackages = with pkgs; [
    # Office applications
    libreoffice
    
    # Internet
    brave
    
    # Media
    vlc
    
    # Additional tools for installed systems
    gnome.gnome-disk-utility
  ];

  # Enable auto-mounting for removable media
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  
  # Enable printer support
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # Enable scanner support
  hardware.sane.enable = true;
  
  # Security recommendations for desktop systems
  security.sudo.wheelNeedsPassword = true;  # Require password for sudo
  
  # System-wide XDG defaults
  xdg.mime.enable = true;
  xdg.icons.enable = true;
  
  # System backup and snapshot support (optional, for btrfs)
  # services.snapper.configs = {
  #   home = {
  #     SUBVOLUME = "/home";
  #     ALLOW_USERS = [ "bloom" ];
  #     TIMELINE_CREATE = true;
  #     TIMELINE_CLEANUP = true;
  #   };
  # };
}
