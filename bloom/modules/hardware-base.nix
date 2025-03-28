{ config, lib, pkgs, ... }:

{
  # ==== Firmware and CPU Microcode ====
  # Enable redistributable firmware (safer than enableAllFirmware)
  # This provides essential firmware for most hardware without including potentially problematic blobs
  hardware.enableRedistributableFirmware = true;
 
  # CPU microcode updates (security and stability)
  # These provide important security patches and stability improvements for processors
  hardware.cpu = {
    intel.updateMicrocode = lib.mkDefault true;
    amd.updateMicrocode = lib.mkDefault true;
  };
 
  # ==== Graphics Support ====
  # Basic OpenGL support - enables hardware acceleration for most applications
  hardware.opengl = {
    enable = true;
    # Uncomment the following if you need 32-bit application support (like Steam)
    # driSupport32Bit = true;
  };

  # X11 display server - required for graphical environments
  services.xserver = {
    enable = true;
    
    # Most compatible video drivers - modesetting is preferred when available
    # fbdev is a fallback for hardware without modesetting support
    videoDrivers = [ "modesetting" "fbdev" ];
    
    # Input device support through libinput
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;              # Enable tap-to-click
        naturalScrolling = true;     # Content moves in direction of finger movement (like smartphones)
        disableWhileTyping = true;   # Prevents accidental cursor movement while typing
      };
    };
    
    # ==== Display Manager ====
    # Uncomment ONE of these display managers to handle login screens
    # displayManager.gdm.enable = true;       # GNOME Display Manager (recommended for GNOME)
    # displayManager.sddm.enable = true;      # Simple Desktop Display Manager (good for KDE)
    # displayManager.lightdm.enable = true;   # Lightweight Display Manager (minimal option)
    
    # ==== Desktop Environment ====
    # Uncomment ONE desktop environment you prefer
    # desktopManager.gnome.enable = true;     # Full-featured, user-friendly environment
    # desktopManager.plasma5.enable = true;   # Feature-rich, highly customizable
    # desktopManager.xfce.enable = true;      # Lightweight but complete desktop
    # windowManager.i3.enable = true;         # Tiling window manager (minimal, keyboard-focused)
  };

  # ==== Audio Configuration ====
  # Real-time kit for PipeWire (allows applications to request real-time priority)
  security.rtkit.enable = true;
  
  # PipeWire audio server - modern replacement for PulseAudio and JACK
  services.pipewire = {
    enable = true;
    alsa.enable = true;              # ALSA applications support
    alsa.support32Bit = true;        # Support for 32-bit ALSA applications
    pulse.enable = true;             # PulseAudio compatibility
    # jack.enable = true;            # Uncomment for JACK application support
  };
 
  # ==== Filesystem Support ====
  # Support for various filesystems
  boot.supportedFilesystems = [ 
    "ext4"     # Standard Linux filesystem
    "btrfs"    # Modern CoW filesystem with snapshots
    "vfat"     # FAT32 compatibility (required for EFI)
    "ntfs"     # Windows filesystem compatibility
  ];
 
  # ==== Hardware Monitoring Tools ====
  environment.systemPackages = with pkgs; [
    pciutils   # lspci - list PCI devices
    usbutils   # lsusb - list USB devices
    lshw       # list hardware
    hwinfo     # hardware information
    # inxi      # Uncomment for a user-friendly system information tool
    # smartmontools  # Uncomment for disk health monitoring
  ];
 
  # ==== Networking Configuration ====
  networking = {
    # Enable NetworkManager for easy network configuration
    networkmanager = {
      enable = true;
      
      # IMPORTANT: Don't set wifi.backend = "iwd" here as it causes conflicts
      # Instead, use NetworkManager's default wpa_supplicant for compatibility
    };
    
    # DNS configuration
    # Option 1: Let NetworkManager handle DNS (default, recommended)
    # Option 2: Configure a specific DNS resolver (uncomment and modify as needed)
    # nameservers = [ "1.1.1.1" "9.9.9.9" ];  # Cloudflare and Quad9
    
    # Disable NixOS DHCP when using NetworkManager
    useDHCP = false;
    dhcpcd.enable = false;
    
    # Explicitly disable wpa_supplicant to avoid conflicts
    # NetworkManager has its own wpa_supplicant instance
    wireless.enable = false;
  };

  # ==== User Configuration ====
  # IMPORTANT: Replace myuser with your actual username
  users.users.myuser = { 
    isNormalUser = true;  # Required - must specify either isNormalUser or isSystemUser
    description = "Main User";
    group = "myuser";  # Create a primary group for the user with the same name
    extraGroups = [ 
      "networkmanager"  # Required for NetworkManager GUI access
      "wheel"           # Uncomment for sudo access
    ];
    # Add other user configuration here
    # home = "/home/myuser";  # Uncomment if you need to specify home directory
  };
  
  # Define the user's primary group
  users.groups.myuser = {};
  
  # Optionally enable power management and TLP for laptops
  # services.tlp.enable = true;
  
  # Optionally enable bluetooth
  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;  # Bluetooth manager
}
