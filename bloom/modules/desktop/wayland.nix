# Wayland-specific configuration for Bloom Nix
{ config, lib, pkgs, ... }:

{
  # Enable Wayland for GDM (though we're using SDDM, this helps with libraries)
  services.xserver.displayManager.gdm.wayland = true;
  
  # Add Wayland-specific packages
  environment.systemPackages = with pkgs; [
    # Wayland core utilities
    wl-clipboard
    xwayland
    wayland
    wayland-utils
    wayland-protocols
    
    # Screenshot and screen recording tools that work well on Wayland
    grim
    slurp
    wf-recorder
    
    # Color picker for Wayland
    wl-color-picker
    
    # Screen sharing support
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    pipewire # Needed for screen sharing
  ];
  
  # Environment variables for better Wayland compatibility
  environment.sessionVariables = {
    # For Firefox
    MOZ_ENABLE_WAYLAND = "1";
    
    # For Qt applications
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    
    # For GTK applications
    GDK_BACKEND = "wayland";
    
    # For Java applications (fixes white screens in some Java apps)
    _JAVA_AWT_WM_NONREPARENTING = "1";
    
    # For SDL applications
    SDL_VIDEODRIVER = "wayland";
    
    # For Elementary/EFL applications
    ELM_DISPLAY = "wl";
    ECORE_EVAS_ENGINE = "wayland";
    ELM_ENGINE = "wayland";
    
    # For Clutter applications
    CLUTTER_BACKEND = "wayland";
    
    # Electron apps
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
  
  # XDG portal configuration for screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-kde ];
    config.common.default = "kde";
  };
  
  # Hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  
  # Support for DRM (Direct Rendering Manager) - helps with graphics
  hardware.graphics.enable = lib.mkDefault true;
  
  # PipeWire configuration optimized for Wayland
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    
    # Low latency configuration
    config.pipewire = {
      "context.properties" = {
        "link.max-buffers" = 16;
        "log.level" = 2;
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 8192;
      };
    };
  };
}
