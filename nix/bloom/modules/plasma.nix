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
      theme = "ChromeOS-dark";
    };
    autoLogin = {
      enable = true;
      user = lib.mkForce "bloom";
    };
    defaultSession = "plasma";
  };

  # Essential packages - using kdePackages namespace for Plasma 6
  environment.systemPackages = with pkgs; [
    kdePackages.plasma-workspace
    kdePackages.plasma-desktop
    kdePackages.plasma-nm
    kdePackages.plasma-pa
    kdePackages.kwayland
    kdePackages.kwin
    kdePackages.powerdevil
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.spectacle
    kdePackages.gwenview
    kdePackages.okular
    firefox-wayland
    kdePackages.breeze-icons
    kdePackages.breeze-gtk
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

  # XDG portals
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
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
