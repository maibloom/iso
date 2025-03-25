nixosConfigurations.minimal-iso = mkNixosConfig {
  modules = [
    # ISO image creation module from nixpkgs
    "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

    # Just the essential modules
    ./modules/base/default.nix
    ./modules/hardware/default.nix

    # VM support
    vmSupportModule

    # Minimal desktop
    {
      # Enable X server
      services.xserver.enable = true;
      
      # Use a lightweight desktop environment (XFCE instead of Plasma)
      services.xserver.desktopManager.xfce.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      
      # Auto-login
      services.xserver.displayManager.autoLogin = {
        enable = true;
        user = "nixos";
      };
      
      # Create a user
      users.users.nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "video" ];
        initialPassword = "";
      };
      
      # Allow sudo without password
      security.sudo.wheelNeedsPassword = false;
      
      # Add basic packages
      environment.systemPackages = with pkgs; [
        firefox
        xfce.xfce4-terminal
        gparted
      ];
      
      # ISO settings
      isoImage = {
        edition = "minimal";
        isoName = "bloom-minimal.iso";
        makeEfiBootable = true;
        makeUsbBootable = true;
      };
    }
  ];
};
