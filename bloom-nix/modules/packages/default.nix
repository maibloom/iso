# Core packages for Bloom Nix - Flake compatible
{ config, pkgs, lib, inputs, outputs, ... }:

{
  # Define options for package groups
  options.bloom.packages = {
    office = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to include office applications";
    };
    
    development = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to include development tools";
    };
    
    multimedia = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to include multimedia applications";
    };
  };
  
  # All configuration settings must be inside the 'config' attribute
  # when the module defines options
  config = lib.mkMerge [
    # System packages that should be available on all installations
    {
      environment.systemPackages = with pkgs; [
        # CLI essentials
        vim nano wget curl git
        htop lsof pciutils usbutils
        zip unzip file tree rsync
        
        # Desktop environment support
        libsForQt5.packagekit-qt
        libsForQt5.qt5.qtgraphicaleffects
        
        # Filesystem tools
        ntfs3g fuse exfat
        
        # Web browser
        brave
        
        # Media support
        ffmpeg
        libdvdcss
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
      ];
    }
    
    # Office applications
    (lib.mkIf config.bloom.packages.office {
      environment.systemPackages = with pkgs; [
        libreoffice
      ];
    })
    
    # Development tools
    (lib.mkIf config.bloom.packages.development {
      environment.systemPackages = with pkgs; [
        vscode
        git
        gnumake
        gcc
        rustup
      ];
    })
    
    # Multimedia applications
    (lib.mkIf config.bloom.packages.multimedia {
      environment.systemPackages = with pkgs; [
        vlc
        gimp
      ];
    })
  ];
}
