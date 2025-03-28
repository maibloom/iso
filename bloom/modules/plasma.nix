# modules/plasma.nix
{ config, lib, pkgs, ... }:

{
  # Plasma 6 configuration
  services.desktopManager.plasma6 = {
    enable = true;
  };

  # Display manager configuration
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
    };
    autoLogin = {
      enable = true;
      user = "bloom";
    };
    defaultSession = "plasma";
  };

  # Essential packages
  environment.systemPackages = with pkgs; [
    plasma-workspace
    plasma-desktop
    plasma-nm
    plasma-pa
    kwayland
    kwin
    powerdevil
    dolphin
    konsole
    kate
    ark
    spectacle
    gwenview
    okular
    firefox-wayland
    breeze-icons
    breeze-gtk
    wl-clipboard
    xdg-desktop-portal
    vlc
  ];

  # Sound configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # XDG portals (FIXED)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ]; # Use kdePackages namespace
    config.common.default = "kde";
  };

  # Environment variables
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
  };
}
