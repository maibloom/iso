# Hardware support configuration for Bloom Nix - Flake compatible
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Use modulesPath from the flake context
    "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
    
    # You can add hardware-specific imports here, e.g.:
    # inputs.nixos-hardware.nixosModules.dell-xps-15-9500
  ];

  #######################################################################
  # Kernel and Boot Configuration
  #######################################################################
 
  # Use latest kernel for maximum hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;
 
  # Balanced kernel parameters for good hardware support while keeping boot messages visible
  boot.kernelParams = [
    # Performance and logging settings
    "quiet"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    
    # Security hardening
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    
    # Hardware detection and power management
    "acpi_osi=Linux"
  ];

  # Graphics for Wayland - consolidated all graphics settings here
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # If you need 32-bit support
    extraPackages = with pkgs; [
      mesa
      libdrm
      libglvnd
      # Add additional graphics packages
      vaapiIntel 
      vaapiVdpau 
      libvdpau-va-gl 
      intel-media-driver
    ];
  };

  # Re-enable standard kernel module detection
  boot.initrd.includeDefaultModules = true;
 
  # Critical kernel modules for device initialization
  boot.initrd.availableKernelModules = [
    # Storage controllers - comprehensive support
    "ahci" "sd_mod" "usb_storage" "usbhid" "xhci_pci" "nvme"
    "virtio_blk" "virtio_pci" "sr_mod" "mmc_block"
    
    # File systems - common formats
    "vfat" "ntfs3" "btrfs" "xfs" "ext4"
    
    # Hardware encryption support
    "aesni_intel" "cryptd"
    
    # Network adapters - common types
    "e1000e" "r8169" "igb"
    
    # Graphics adapters
    "i915" "amdgpu" "radeon" "nouveau"
  ];
 
  # Support all major filesystems
  boot.supportedFilesystems = [ "ntfs" "vfat" "exfat" "ext4" "btrfs" "xfs" ];
 
  # Explicitly disable looking for Hyper-V modules if not needed
  boot.blacklistedKernelModules = [
    "hv_balloon" "hv_netvsc" "hvstorvsc" "hv_utils" "hv_vmbus"
  ];

  #######################################################################
  # udev and Hardware Detection
  #######################################################################
 
  # Ensure udev has necessary programs and rules
  services.udev = {
    enable = true;
    # Include essential rules
    extraRules = ''
      # Rules for common devices - helps with hardware detection
      KERNEL=="sd*", ATTRS{vendor}=="*", ACTION=="add", IMPORT{program}="scsi_id -g -u -d /dev/$name"
    '';
  };

  # Include additional firmware for better hardware support
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
 
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
 
  # Additional firmware - get from nixpkgs
  hardware.firmware = with pkgs; [ linux-firmware firmwareLinuxNonfree ];
 
  #######################################################################
  # Graphics and Display
  #######################################################################
 
  # NVIDIA support
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
 
  #######################################################################
  # Input Devices
  #######################################################################
 
  # Touchpad support with good defaults
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      clickMethod = "clickfinger";
    };
  };
 
  #######################################################################
  # Peripheral Support
  #######################################################################
 
  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
 
  # Printer support
  services.printing.enable = true;
 
  # Scanner support
  hardware.sane.enable = true;
 
  #######################################################################
  # Essential System Packages
  #######################################################################
 
  # Hardware-related tools and utilities
  environment.systemPackages = with pkgs; [
    # Hardware information and management
    lshw pciutils usbutils
    lm_sensors
    dmidecode
    
    # Storage management
    ntfs3g
    parted
    gptfdisk
    hdparm
    smartmontools
    
    # Network tools
    ethtool
    iw
    wirelesstools
  ];

  #######################################################################
  # Necessary Services
  #######################################################################
 
  # Auto-mounting support
  services.devmon.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Hardware sensor monitoring
  services.thermald.enable = true;
}
