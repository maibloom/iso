# modules/hardware-support.nix
# Hardware support configuration for Bloom Nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  #######################################################################
  # Kernel and Boot Configuration
  #######################################################################
 
  # Use latest kernel for maximum hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;
 
  # Optimized kernel parameters
  boot.kernelParams = [
    # Performance and logging
    "quiet" "splash" "vga=current"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3" "udev.log_priority=3"
    
    # Security hardening
    "slab_nomerge" "init_on_alloc=1" "init_on_free=1"
    "page_alloc.shuffle=1"
    
    # CPU vulnerability mitigations
    "spectre_v2=on" "spec_store_bypass_disable=on"
    "tsx=off" "tsx_async_abort=full"
    
    # Hardware detection and power management
    "acpi_osi=Linux" "intel_pstate=active"
  ];

  # Extensive kernel module support - MODIFIED: removed problematic modules
  boot.initrd.availableKernelModules = [
    # Storage controllers
    "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" "sd_mod"
    "usb_storage" "nvme" "mmc_block"
    
    # File systems - removed reiserfs which isn't available in 6.13.3
    "vfat" "ntfs3" "btrfs" "xfs" "f2fs" "jfs" "ext4"
    
    # Hardware encryption
    "aesni_intel" "cryptd" "dm_crypt" "dm_integrity"
    
    # Security modules
    "tpm_tis" "tpm_crb"
    
    # Network adapters (common ones)
    "e1000e" "r8169" "rtl8169" "igb" "ixgbe" "iwlwifi" "ath9k" "ath10k_pci"
    
    # Graphics adapters
    "i915" "amdgpu" "radeon" "nouveau"
  ];
 
  # CPU virtualization support
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
 
  # Blacklist potentially dangerous modules
  boot.blacklistedKernelModules = [ "thunderbolt" "firewire_core" ];
 
  # Support only filesystems that are definitely available in current kernel
  # MODIFIED: removed reiserfs
  boot.supportedFilesystems = [ "ntfs" "vfat" "exfat" "ext4" "btrfs" "xfs" "f2fs" ];
 
  # Note: ZFS configuration is now handled by NixOS modules to avoid conflicts
 
  #######################################################################
  # Filesystem Configuration
  #######################################################################
 
  # Root filesystem with security options
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [
      "defaults" "relatime" "noatime"
      "data=ordered" "errors=remount-ro"
    ];
    neededForBoot = true;
  };

  # Conditionally add boot partition if not already defined
  fileSystems."/boot" = lib.mkIf (!config.fileSystems ? "/boot") {
    device = lib.mkDefault "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "defaults" "umask=0077" "shortname=winnt" "utf8" "flush" ];
  };

  # Secure temporary filesystem
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=1777" "size=50%" "nosuid" "nodev" "noexec" ];
  };

  # No swap by default (can be enabled through installer)
  swapDevices = [ ];
 
  # Auto-mounting support
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;

  #######################################################################
  # Hardware Support
  #######################################################################
 
  # Firmware packages
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
 
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
 
  # Additional firmware
  hardware.firmware = with pkgs; [ linux-firmware firmwareLinuxNonfree ];
 
  # OpenGL support
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiIntel vaapiVdpau libvdpau-va-gl intel-media-driver
    ];
  };
 
  # NVIDIA driver configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.finegrained = true;
  };
 
  # Touchpad support
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      clickMethod = "clickfinger";
      accelProfile = "adaptive";
      accelSpeed = "0.5";
    };
  };
 
  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General = {
      ControllerMode = "dual";
      FastConnectable = true;
      Privacy = true;
      JustWorksRepairing = "always";
    };
  };
 
  # Printer and scanner support
  services.printing = {
    enable = true;
    browsing = true;
    webInterface = true;
    drivers = with pkgs; [
      gutenprint gutenprintBin hplip brlaser
      brgenml1lpr cnijfilter2 splix
    ];
  };
 
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [ sane-airscan hplipWithPlugin ];
  };
 
  # Network configuration
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.dns = "systemd-resolved";
 
  # Secure DNS resolution
  services.resolved = {
    enable = true;
    dnssec = "true";
    fallbackDns = ["9.9.9.9" "1.1.1.1"];
  };
 
  # Basic firewall
  networking.firewall = {
    enable = true;
    allowPing = false;
  };
 
  # Power management
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";
 
  # TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };
 
  # Sensor monitoring
  hardware.sensor.iio.enable = true;
  services.thermald.enable = true;
 
  # Add lm_sensors package and service
  environment.systemPackages = with pkgs; [ 
    lm_sensors 
    ntfs3g  # Explicitly add NTFS support package
  ];
 
  systemd.services.lm-sensors = {
    description = "Initialize hardware sensors";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.lm_sensors}/bin/sensors -s";
    };
  };
 
  # Crash dump support
  boot.crashDump.enable = true;
}
