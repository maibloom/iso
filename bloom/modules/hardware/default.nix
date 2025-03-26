# Enhanced hardware support for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Enable all firmware (may require unfree packages)
  hardware.enableAllFirmware = true;
  
  # Enable firmware for specific components
  hardware.firmware = with pkgs; [
    firmwareLinuxNonfree
    intel-microcode
    amdMicrocode
    
    # Wireless firmware
    wireless-regdb
    
    # Video firmware
    nvidia-firmware
    
    # Bluetooth firmware
    bluez-firmware
  ];
  
  # Hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    
    # Additional packages for hardware acceleration
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI for Intel
      vaapiIntel            # Legacy VAAPI for older Intel
      vaapiVdpau            
      libvdpau-va-gl
      amdvlk                # AMD Vulkan
      rocm-opencl-icd       # OpenCL for AMD
      intel-compute-runtime # OpenCL for Intel
    ];
    
    # 32-bit packages for compatibility with games
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  # Support for NVIDIA GPUs
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  # Bluetooth support
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
  
  # Scanner and printer support
  hardware.sane.enable = true;
  services.printing = {
    enable = true;
    drivers = with pkgs; [ 
      gutenprint
      gutenprintBin
      hplip
      brlaser
      brgenml1lpr
      cnijfilter2
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  # Support for various storage devices
  boot.supportedFilesystems = [ 
    "ext4" "btrfs" "xfs" "ntfs" "fat" "vfat" "exfat" "f2fs"
  ];
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  
  # Support for various hardware sensors
  hardware.sensor.iio.enable = true;
  
  # Better power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };
  
  # Audio enhancements
  sound.enable = true;
  
  # Video driver detection
  services.xserver.videoDrivers = [ 
    "nvidia" "amdgpu" "radeon" "nouveau" "intel" "modesetting" "fbdev" "vesa"
  ];
  
  # Hardware database for device recognition
  services.udev.packages = with pkgs; [
    hwdata
    usb-modeswitch-data
  ];
  
  # Enable CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
  
  # Enable all pulseaudio modules for better hardware compatibility
  hardware.pulseaudio.enable = false; # We use pipewire instead
  hardware.pulseaudio.package = pkgs.pulseaudioFull; # Still needed for compatibility
  
  # Enable touchpad support
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      clickMethod = "clickfinger";
    };
  };
  
  # Support for gaming hardware
  hardware.steam-hardware.enable = true;
  
  # Add hardware tools to environment
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    lshw
    dmidecode
    inxi
    hwinfo
    powertop
    acpi
    lm_sensors
    smartmontools
    ethtool
    wavemon
    brightnessctl
  ];
}
