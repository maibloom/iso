{ config, lib, pkgs, ... }:

{
  # ISO image specific configurations
  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    # Use generic names to avoid issues
    isoName = lib.mkForce "bloom-nix.iso";
    volumeID = lib.mkForce "BLOOM_NIX";
    appendToMenuLabel = lib.mkForce "Bloom Nix";
  };
 
  # Live CD user does not get a password
  users.users.bloom.password = "";

  boot.loader.grub.enable = true;
  boot.supportedFilesystems = [ "ext4" ];
 
  # Allow the user to log in without a password on the TTY
  # Use mkForce to ensure our value takes precedence over the default "nixos"
  services.getty.autologinUser = lib.mkForce "bloom";
 
  # Create a simple desktop entry for installation
  environment.etc."skel/Desktop/terminal.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Terminal
    Comment=Open a terminal to install the system
    Exec=konsole
    Icon=utilities-terminal
    Terminal=false
    Categories=System;
  '';
 
  # Documentation to help users install
  environment.etc."bloom-nix/docs/installation.txt".text = ''
    Installing Bloom Nix
    ===================
    
    For a guided installation, open a terminal and use the following commands:
    
    1. Partition your disk:
       sudo cfdisk /dev/sda
    
    2. Format partitions:
       sudo mkfs.ext4 /dev/sda2
       sudo mkswap /dev/sda1
     
    3. Mount filesystems:
       sudo mount /dev/sda2 /mnt
       sudo mkdir -p /mnt/boot
       sudo mount /dev/sda1 /mnt/boot
    
    4. Generate NixOS configuration:
       sudo nixos-generate-config --root /mnt
    
    5. Edit configuration:
       sudo nano /mnt/etc/nixos/configuration.nix
    
    6. Install NixOS:
       sudo nixos-install
    
    7. Reboot:
       sudo reboot
  '';
}
