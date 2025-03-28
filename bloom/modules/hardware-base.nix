{ config, lib, pkgs, ... }:

{
  # Enable redistributable firmware (safer than enableAllFirmware)
  hardware.enableRedistributableFirmware = true;
  
  # CPU microcode updates (security and stability)
  hardware.cpu = {
    intel.updateMicrocode = lib.mkDefault true;
    amd.updateMicrocode = lib.mkDefault true;
  };
  
  # Graphics - minimal but universal support
  hardware.opengl.enable = true;

  # Core sound support with PipeWire
  security.rtkit.enable = true;
  
  # Input device support
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
    };
  };
  
  # Most compatible video drivers
  services.xserver.videoDrivers = [ "modesetting" "fbdev" ];
  
  # Support for various filesystems
  boot.supportedFilesystems = [ "ext4" "btrfs" "vfat" "ntfs" ];
  
  # Hardware monitoring tools
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    lshw
    hwinfo
  ];
}
