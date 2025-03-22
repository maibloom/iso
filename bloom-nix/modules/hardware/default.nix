# Enhanced hardware support configuration for Bloom Nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Use hardware profiles from nixos-hardware when available
    # This gives better support for specific hardware models
    # Uncomment specific hardware profiles as needed
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
  ];

  #######################################################################
  # Kernel and Boot Configuration
  #######################################################################
 
  # Use latest kernel for maximum hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;
 
  # Optimize kernel parameters for better hardware support and performance
  boot.kernelParams = [
    # Performance and logging settings
    "quiet"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    
    # Security hardening
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "vsyscall=none"
    "randomize_kstack_offset=on"
    
    # Hardware detection and power management
    "acpi_osi=Linux"
    "acpi_enforce_resources=lax"
    "pcie_aspm=force"
    "memhp_default_state=online"
    "usbcore.autosuspend=1"
    
    # Performance optimizations
    "mitigations=auto"
    "nowatchdog"
    "nohz_full=1-${toString (config.nix.settings.max-jobs - 1)}"
  ];

  # Graphics for Wayland - consolidated all graphics settings here
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Enable 32-bit graphics support for compatibility
    extraPackages = with pkgs; [
      mesa
      libdrm
      libglvnd
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-media-driver
      amdvlk  # For AMD GPUs
    ];
  };

  # Re-enable standard kernel module detection
  boot.initrd.includeDefaultModules = true;
 
  # More comprehensive kernel modules for device initialization
  boot.initrd.availableKernelModules = [
    # Storage controllers
    "ahci" "sd_mod" "usb_storage" "usbhid" "xhci_pci" "nvme"
    "virtio_blk" "virtio_pci" "sr_mod" "mmc_block" "sdhci_pci"
    "scsi_mod" "uas" "ufs"
    
    # File systems
    "vfat" "ntfs3" "btrfs" "xfs" "ext4" "f2fs" "exfat"
    
    # Hardware encryption support
    "aesni_intel" "cryptd" "aes_x86_64" "crypto_simd"
    
    # Network adapters - common types
    "e1000e" "r8169" "igb" "ixgbe" "iwlwifi" "rtw88" "rtl8821ce"
    "ath9k" "ath10k_core" "ath10k_pci" "mt7921e"
    
    # Graphics adapters
    "i915" "amdgpu" "radeon" "nouveau" "nvidia"
    
    # Thunderbolt support
    "thunderbolt"
    
    # NVMe SSD support
    "nvme_core"
    
    # Storage card readers
    "rtsx_pci" "rtsx_usb"
    
    # Input devices
    "hid_generic" "hid_multitouch" "wacom"
    
    # Webcam support - add UVC module
    "uvcvideo"
  ];
 
  # Support all major filesystems
  boot.supportedFilesystems = [
    "ntfs" "vfat" "exfat" "ext4" "btrfs" "xfs" "f2fs" "zfs"
  ];
 
  # Boot loader options
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = lib.mkDefault true;
    systemd-boot.configurationLimit = 10;
    timeout = 3;
  };

  #######################################################################
  # udev and Hardware Detection
  #######################################################################
 
  # Ensure udev has necessary programs and rules
  services.udev = {
    enable = true;
    packages = with pkgs; [
      gnome.gnome-settings-daemon
      libwacom
      android-udev-rules
    ];
    # Include essential rules
    extraRules = ''
      # Rules for common devices - helps with hardware detection
      KERNEL=="sd*", ATTRS{vendor}=="*", ACTION=="add", IMPORT{program}="scsi_id -g -u -d /dev/$name"
      
      # Fix for some SSDs that don't enable TRIM by default
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTRS{queue/rotational}=="0", ATTR{queue/discard_max_bytes}!="0", ATTR{queue/read_ahead_kb}="2048", ATTR{queue/discard_granularity}="512"
      
      # Rules for specific devices like drawing tablets, etc.
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666"
      
      # Power management for USB devices
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
      
      # Automatically mount USB drives
      ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --automount=yes --collect $devnode /media"
      
      # Webcam permissions
      SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
    '';
  };

  # Include additional firmware for better hardware support
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
 
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
 
  # Additional firmware
  hardware.firmware = with pkgs; [
    linux-firmware
    firmwareLinuxNonfree
    broadcom-bt-firmware
    sof-firmware
  ];
 
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
      accelProfile = "adaptive";
      accelSpeed = 0.3;
    };
    mouse = {
      accelProfile = "adaptive";
      accelSpeed = 0.5;
    };
  };
 
  #######################################################################
  # Peripheral and Device Support
  #######################################################################
 
  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
 
  # Printer support
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      hplipWithPlugin
      brlaser
      brgenml1lpr
      cnijfilter2
    ];
    browsing = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    defaultShared = true;
  };
 
  # Avahi for printer discovery
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
      workstation = true;
    };
  };
 
  # Scanner support
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
      hplipWithPlugin
    ];
  };
 
  # Webcam support - using proper group and kernel module approach
  users.groups.video = {};  # Ensure video group exists
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback  # Add Video4Linux loopback support
  ];
 
  # Android and removable media support
  programs.adb.enable = true;
  services.gvfs.enable = true;  # For MTP device mounting
  services.udisks2.enable = true;  # For auto-mounting
  services.devmon.enable = true;  # For device monitoring
 
  # Thunderbolt support
  services.hardware.bolt.enable = true;

  # Smartcard/YubiKey support
  services.pcscd.enable = true;
  hardware.nitrokey.enable = true;
 
  # iPad/iPhone support
  services.usbmuxd.enable = true;
 
  #######################################################################
  # Power Management
  #######################################################################
 
  # Power management
  services.power-profiles-daemon.enable = true; # Modern power profiles
  services.tlp = {
    enable = true;
    settings = {
      # Battery charge thresholds (if supported)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 85;
      
      # CPU frequency scaling
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Device power saving
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      
      # PCIe power management
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersave";
      
      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };
 
  # Thermal management
  services.thermald.enable = true;
 
  # Auto-cpufreq for dynamic CPU frequency management
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
 
  #######################################################################
  # Essential System Packages for Hardware Management
  #######################################################################
 
  # Hardware-related tools and utilities
  environment.systemPackages = with pkgs; [
    # Hardware information and management
    lshw pciutils usbutils
    lm_sensors
    dmidecode
    hwinfo
    inxi
    
    # Storage management
    ntfs3g
    exfat
    parted
    gptfdisk
    hdparm
    smartmontools
    nvme-cli
    
    # Network tools
    ethtool
    iw
    wirelesstools
    wavemon
    
    # Device management
    usbutils
    libimobiledevice
    
    # Power management tools
    powertop
    tlp
    acpi
    
    # Thermal monitoring
    psensor
    
    # Webcam utilities
    v4l-utils
    guvcview
  ];

  #######################################################################
  # Video Acceleration and GPU Support
  #######################################################################
 
  # Video acceleration
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
 
  # Support for specific GPU types
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = lib.mkDefault false;
      # Configuration for Optimus laptops with NVIDIA GPU
      # intelBusId = "PCI:0:2:0";
      # nvidiaBusId = "PCI:1:0:0";
    };
  };
}
