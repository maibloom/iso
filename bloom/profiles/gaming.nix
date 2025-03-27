# Gaming profile for Bloom Nix
{ config, lib, pkgs, ... }:

{
  imports = [
    # Include default profile
    ./default.nix
  ];
  
  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  # Enable Gamemode for better gaming performance
  programs.gamemode.enable = true;
  
  # Support for gaming hardware
  hardware.xpadneo.enable = true;
  hardware.steam-hardware.enable = true;
  
  # Add gaming packages
  environment.systemPackages = with pkgs; [
    # Game launchers
    steam
    lutris
    heroic
    
    # Wine and Proton
    wine
    winetricks
    protonup-qt
    protontricks
    
    # Performance tools
    gamemode
    mangohud
    
    # Discord for gaming communication
    discord
    
    # OBS for streaming
    obs-studio
    
    # Gaming utilities
    input-remapper
    antimicrox
    
    # Controllers support
    jstest-gtk
    
    # Emulators
    retroarch
  ];
  
  # Performance optimizations for gaming
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.max_map_count" = 16777216;
  };
  
  # CPU frequency scaling for better gaming performance
  services.thermald.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  
  # Optimize IO scheduler for gaming
  services.udev.extraRules = ''
    # Set IO scheduler for SSDs and NVMes
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
  '';

  # Enable 32-bit support (needed for many games)
  hardware.opengl.driSupport32Bit = true;
  
  # Enable Vulkan support
  hardware.opengl.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
  ];
  
  # Enable Vulkan support for 32-bit apps
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [
    vulkan-loader
  ];
  
  # Enable ACO compiler for better AMD performance
  environment.variables = {
    RADV_PERFTEST = "aco";
  };
}
