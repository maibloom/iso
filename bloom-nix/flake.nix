{
  description = "Bloom Nix - A modern NixOS distribution with GNOME";

  inputs = {
    # Core Nix inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager for user configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add other useful inputs
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nix-colors, ... }@inputs:
    let
      lib = nixpkgs.lib;

      # System architecture
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;

      # Function to create a NixOS configuration
      mkNixosConfig = {
        system ? "x86_64-linux",
        modules ? []
      }: lib.nixosSystem {
          inherit system;
          modules = [
            # Include home-manager as a NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit (self) outputs;
              };
            }
          ] ++ modules;  # Properly concatenate the module lists
          specialArgs = {
            inherit inputs;
            inherit (self) outputs;
          };
        };
        
      # VM support module to ensure stable operation in virtual machines
      vmSupportModule = { config, lib, pkgs, ... }: {
        # Enable necessary kernel modules for VMs
        boot.initrd.availableKernelModules = [ 
          "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" 
          "ahci" "xhci_pci" "sd_mod" "usb_storage"
        ];
        boot.initrd.kernelModules = [ "kvm-intel" "kvm-amd" ];
        
        # Optimize kernel parameters for VMs
        boot.kernelParams = [
          # Improve VM performance and reduce resources
          "mem_sleep_default=deep"
          "usbcore.autosuspend=0"
          # Prevent GPU-related hangs
          "nomodeset"
          # Improve boot speed
          "panic=60"
          "boot.shell_on_fail"
          # Prevent some kernel panics in VMs
          "ibt=off"
        ];
        
        # Enable firmware that might be needed
        hardware.enableRedistributableFirmware = true;
        
        # VM-friendly graphics drivers
        services.xserver.videoDrivers = [ 
          "qxl"       # For QEMU/Spice
          "vmware"    # For VMware
          "modesetting" # Fallback
          "fbdev"     # Last resort
        ];
        
        # SPICE agent for better mouse, clipboard, and resolution handling
        services.spice-vdagentd.enable = true;
        
        # Use X11 instead of Wayland in VMs for better compatibility
        services.xserver.displayManager.gdm.wayland = lib.mkForce false;
        
        # Add VM-related packages
        environment.systemPackages = with pkgs; [
          spice-vdagent    # For QEMU/KVM with SPICE
          pciutils         # For hardware debugging
          usbutils         # For USB debugging
        ];
        
        # Ensure display size can be adjusted dynamically
        services.xserver.resolutions = lib.mkIf (lib.versionAtLeast lib.version "23.05") [
          { x = 1024; y = 768; }
          { x = 1280; y = 720; }
          { x = 1366; y = 768; }
          { x = 1920; y = 1080; }
        ];
        
        # Reduce timeout for shutting down services to prevent hanging
        systemd.extraConfig = ''
          DefaultTimeoutStopSec=15s
        '';
      };
    in {
      # ISO image configuration
      nixosConfigurations.iso = mkNixosConfig {
        modules = [
          # ISO image creation module from nixpkgs
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/gnome.nix  # Changed from plasma.nix to gnome.nix
          ./modules/desktop/bloom-theme.nix  # Added the Bloom Theme module
          ./modules/branding/default.nix
          ./modules/packages/default.nix

          # ISO-specific configurations
          ./hosts/iso/default.nix
          
          # Add VM support module
          vmSupportModule
         
          # Customize ISO properties with priority resolution
          {
            isoImage = {
              edition = "bloom-gnome";
              isoName = "bloom-gnome-${builtins.substring 0 8 self.lastModifiedDate or "19700101"}-${self.shortRev or "dirty"}.iso";
              # Use lib.mkForce to give this definition higher priority
              appendToMenuLabel = lib.mkForce " Bloom Nix GNOME Edition";
              makeEfiBootable = true;
              makeUsbBootable = true;
            };
            
            # Force auto-login to be reliable in VMs
            services.displayManager.autoLogin = {
              enable = lib.mkForce true;
              user = lib.mkForce "nixos";
            };
            
            # Reduce memory usage for VM compatibility
            boot.tmp.cleanOnBoot = true;
            services.xserver.displayManager.job.logToFile = false;
          }
        ];
      };

      # Installed system configuration
      nixosConfigurations.desktop = mkNixosConfig {
        modules = [
          # Bloom Nix modules
          ./modules/base/default.nix
          ./modules/hardware/default.nix
          ./modules/desktop/gnome.nix  # Changed from plasma.nix to gnome.nix
          ./modules/desktop/bloom-theme.nix  # Added the Bloom Theme module
          ./modules/branding/default.nix
          ./modules/packages/default.nix

          # Desktop-specific configurations
          ./hosts/desktop/default.nix
        ];
      };

      # Make ISO image available as a package
      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        default = self.packages.${system}.iso;
      });

      # Add devShell for development environment
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              nixpkgs-fmt  # Nix formatter
            ];
            shellHook = ''
              echo "Bloom Nix development environment with GNOME"
              echo "Run 'nix build .#iso' to build the ISO"
            '';
          };
        }
      );
    };
}
