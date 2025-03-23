#!/usr/bin/env python3
"""
Bloom Nix Installer - Sudo Helper Script

This script provides a secure interface for the Streamlit installer to perform
privileged operations. It only allows specific, pre-defined operations to be
performed, with validation of inputs to prevent command injection.

This approach keeps the Streamlit application running as a regular user while
providing controlled access to system operations that require root privileges.
"""

import os
import sys
import json
import subprocess
import logging
import argparse
import re
import shutil
from pathlib import Path
from typing import Dict, List, Any, Tuple, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/tmp/bloom-nix-installer-sudo.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("sudo-helper")

# Constants
MOUNT_POINT = "/mnt"

# Security: Validate that this script is being run with sudo
if os.geteuid() != 0:
    print("This script must be run with sudo privileges.")
    sys.exit(1)

# Security: Whitelist of allowed commands
ALLOWED_COMMANDS = {
    "list_disks",
    "auto_partition_uefi",
    "auto_partition_bios",
    "get_partition_info",
    "launch_partitioning_tool",
    "mount_filesystems",
    "generate_hardware_config",
    "copy_project_files",
    "create_system_config",
    "install_nixos",
    "install_bootloader",
    "finalize_installation",
    "reboot"
}

def validate_disk_path(disk_path: str) -> bool:
    """
    Validate that a disk path is a valid block device
    """
    # Check that it's a valid format like /dev/sda or /dev/nvme0n1
    if not re.match(r"^/dev/[a-zA-Z0-9]+$", disk_path):
        logger.error(f"Invalid disk path format: {disk_path}")
        return False
    
    # Check that it exists and is a block device
    if not os.path.exists(disk_path) or not os.path.isblock(disk_path):
        logger.error(f"Disk path does not exist or is not a block device: {disk_path}")
        return False
    
    return True

def list_disks() -> str:
    """
    Get a list of available disks
    Returns: JSON string with disk information
    """
    logger.info("Listing available disks")
    disks = []
    
    try:
        # Use lsblk to get disk information
        cmd = ["lsblk", "-dno", "NAME,SIZE,MODEL", "-e", "7,11"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            logger.error(f"Failed to get disk list: {result.stderr}")
            return json.dumps([])
        
        # Parse the output
        for line in result.stdout.splitlines():
            parts = line.strip().split(maxsplit=2)
            disk_info = {
                "name": parts[0],
                "size": parts[1]
            }
            if len(parts) > 2:
                disk_info["model"] = parts[2]
            else:
                disk_info["model"] = "Unknown"
            
            disks.append(disk_info)
        
        return json.dumps(disks)
    except Exception as e:
        logger.error(f"Error listing disks: {str(e)}")
        return json.dumps([])

def auto_partition_uefi(disk_path: str) -> bool:
    """
    Automatically partition a disk for UEFI systems
    """
    logger.info(f"Auto-partitioning disk {disk_path} for UEFI")
    
    # Validate the disk path
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Create a new GPT partition table
        subprocess.run(["parted", "-s", disk_path, "mklabel", "gpt"], check=True)
        
        # Create EFI partition (512MB)
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "fat32", "1MiB", "513MiB"], check=True)
        subprocess.run(["parted", "-s", disk_path, "set", "1", "esp", "on"], check=True)
        
        # Create root partition (rest of disk)
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "ext4", "513MiB", "100%"], check=True)
        
        # Wait for partitions to be visible
        subprocess.run(["udevadm", "settle"], check=True)
        
        # Get the partition devices
        disk_name = os.path.basename(disk_path)
        
        # Handle different disk naming schemes (e.g., sda vs nvme0n1)
        if disk_name.startswith("nvme") or disk_name.startswith("mmcblk"):
            efi_part = f"{disk_path}p1"
            root_part = f"{disk_path}p2"
        else:
            efi_part = f"{disk_path}1"
            root_part = f"{disk_path}2"
        
        # Format the partitions
        subprocess.run(["mkfs.fat", "-F32", efi_part], check=True)
        subprocess.run(["mkfs.ext4", "-F", root_part], check=True)
        
        logger.info(f"Successfully partitioned {disk_path} for UEFI")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to partition disk {disk_path}: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error partitioning disk {disk_path}: {str(e)}")
        return False

def auto_partition_bios(disk_path: str) -> bool:
    """
    Automatically partition a disk for BIOS systems
    """
    logger.info(f"Auto-partitioning disk {disk_path} for BIOS")
    
    # Validate the disk path
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Create a new MBR partition table
        subprocess.run(["parted", "-s", disk_path, "mklabel", "msdos"], check=True)
        
        # Create BIOS boot partition (1MB)
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "1MiB", "2MiB"], check=True)
        subprocess.run(["parted", "-s", disk_path, "set", "1", "bios_grub", "on"], check=True)
        
        # Create root partition (rest of disk)
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "ext4", "2MiB", "100%"], check=True)
        
        # Wait for partitions to be visible
        subprocess.run(["udevadm", "settle"], check=True)
        
        # Get the partition devices
        disk_name = os.path.basename(disk_path)
        
        # Handle different disk naming schemes (e.g., sda vs nvme0n1)
        if disk_name.startswith("nvme") or disk_name.startswith("mmcblk"):
            root_part = f"{disk_path}p2"
        else:
            root_part = f"{disk_path}2"
        
        # Format the root partition
        subprocess.run(["mkfs.ext4", "-F", root_part], check=True)
        
        logger.info(f"Successfully partitioned {disk_path} for BIOS")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to partition disk {disk_path}: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error partitioning disk {disk_path}: {str(e)}")
        return False

def get_partition_info(disk_path: str) -> str:
    """
    Get information about partitions on a disk
    Returns: JSON string with partition information
    """
    logger.info(f"Getting partition info for {disk_path}")
    
    # Validate the disk path
    if not validate_disk_path(disk_path):
        return json.dumps({"error": "Invalid disk path"})
    
    try:
        # Get partition information using lsblk
        cmd = ["lsblk", "-no", "NAME,SIZE,FSTYPE,MOUNTPOINT", "-p", disk_path]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        partitions = []
        for line in result.stdout.splitlines()[1:]:  # Skip the disk line
            parts = line.strip().split(maxsplit=3)
            if len(parts) >= 3:
                partition = {
                    "path": parts[0],
                    "size": parts[1],
                    "fstype": parts[2]
                }
                if len(parts) > 3:
                    partition["mountpoint"] = parts[3]
                
                partitions.append(partition)
        
        return json.dumps({"disk": disk_path, "partitions": partitions})
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to get partition info for {disk_path}: {str(e)}")
        return json.dumps({"error": f"Failed to get partition info: {str(e)}"})
    except Exception as e:
        logger.error(f"Error getting partition info for {disk_path}: {str(e)}")
        return json.dumps({"error": f"Error: {str(e)}"})

def launch_partitioning_tool(disk_path: str) -> bool:
    """
    Launch a partitioning tool for manual partitioning
    """
    logger.info(f"Launching partitioning tool for {disk_path}")
    
    # Validate the disk path
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Check if we have cfdisk or gparted available
        if shutil.which("gparted"):
            # Launch gparted in a new process
            subprocess.Popen(["gparted", disk_path])
            return True
        elif shutil.which("cfdisk"):
            # Run cfdisk (this will block until it exits)
            subprocess.run(["cfdisk", disk_path], check=True)
            return True
        else:
            logger.error("No partitioning tool found (gparted or cfdisk)")
            return False
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to launch partitioning tool: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error launching partitioning tool: {str(e)}")
        return False

def mount_filesystems(disk_path: str) -> bool:
    """
    Mount the filesystems for installation
    """
    logger.info(f"Mounting filesystems from {disk_path}")
    
    # Validate the disk path
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Get disk name and determine partitions
        disk_name = os.path.basename(disk_path)
        
        # Handle different disk naming schemes
        if disk_name.startswith("nvme") or disk_name.startswith("mmcblk"):
            root_part = f"{disk_path}p2"
            efi_part = f"{disk_path}p1"
        else:
            root_part = f"{disk_path}2"
            efi_part = f"{disk_path}1"
        
        # Create mount point if it doesn't exist
        os.makedirs(MOUNT_POINT, exist_ok=True)
        
        # Mount root filesystem
        subprocess.run(["mount", root_part, MOUNT_POINT], check=True)
        
        # Check if we're using UEFI
        is_uefi = os.path.exists("/sys/firmware/efi")
        if is_uefi:
            # Create and mount EFI partition
            os.makedirs(f"{MOUNT_POINT}/boot/efi", exist_ok=True)
            subprocess.run(["mount", efi_part, f"{MOUNT_POINT}/boot/efi"], check=True)
        
        logger.info(f"Successfully mounted filesystems from {disk_path}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to mount filesystems: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error mounting filesystems: {str(e)}")
        return False

def generate_hardware_config() -> bool:
    """
    Generate NixOS hardware configuration
    """
    logger.info("Generating NixOS hardware configuration")
    
    try:
        # Run nixos-generate-config
        subprocess.run(["nixos-generate-config", "--root", MOUNT_POINT], check=True)
        
        logger.info("Successfully generated hardware configuration")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to generate hardware configuration: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error generating hardware configuration: {str(e)}")
        return False

def copy_project_files() -> bool:
    """
    Copy Bloom Nix project files to the installation
    """
    logger.info("Copying Bloom Nix project files")
    
    try:
        # Create destination directory
        project_dir = os.path.join(MOUNT_POINT, "etc/nixos/bloom-nix")
        os.makedirs(project_dir, exist_ok=True)
        
        # Check for environment variables with project paths
        project_root = os.environ.get("BLOOM_PROJECT_ROOT")
        if not project_root:
            logger.error("BLOOM_PROJECT_ROOT environment variable not found")
            return False
        
        # Copy project structure
        for module in ["base", "desktop", "hardware", "packages", "branding"]:
            env_var = f"BLOOM_MODULE_{module.upper()}"
            module_path = os.environ.get(env_var)
            
            if module_path and os.path.exists(module_path):
                logger.info(f"Copying {module} module from {module_path}")
                dest_dir = os.path.join(project_dir, "modules", module)
                os.makedirs(dest_dir, exist_ok=True)
                
                # Copy module contents
                subprocess.run(["cp", "-r", f"{module_path}/.", dest_dir], check=True)
            else:
                logger.warning(f"Module path for {module} not found or does not exist")
        
        # Copy host configuration
        host_config = os.environ.get("BLOOM_HOST_CONFIG")
        if host_config and os.path.exists(host_config):
            logger.info(f"Copying host configuration from {host_config}")
            dest_dir = os.path.join(project_dir, "hosts/desktop")
            os.makedirs(dest_dir, exist_ok=True)
            
            # Copy host configuration
            subprocess.run(["cp", "-r", f"{host_config}/.", dest_dir], check=True)
        else:
            logger.warning("Host configuration not found or does not exist")
        
        # Create a basic flake.nix if it doesn't exist
        flake_path = os.path.join(project_dir, "flake.nix")
        if not os.path.exists(flake_path):
            logger.info("Creating basic flake.nix")
            with open(flake_path, 'w') as f:
                f.write("""
{
  description = "Bloom Nix System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  {
    nixosConfigurations = {
      bloom = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/desktop
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
  };
}
""")
        
        logger.info("Successfully copied project files")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to copy project files: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Error copying project files: {str(e)}")
        return False

def create_system_config(config_file: str) -> bool:
    """
    Create the NixOS configuration file
    """
    logger.info("Creating NixOS configuration")
    
    try:
        # Load the configuration from the file
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        # Get important configuration values
        hostname = config.get('hostname', 'bloom-nix')
        username = config.get('username', 'user')
        fullname = config.get('fullname', '')
        password = config.get('password', '')
        use_root = config.get('use_root', False)
        root_password = config.get('root_password', '')
        timezone = config.get('timezone', 'America/New_York')
        locale = config.get('locale', 'en_US.UTF-8')
        keyboard = config.get('keyboard', 'us')
        selected_packages = config.get('selected_packages', [])
        use_project_structure = config.get('use_project_structure', False)
        
        # Define package lists for each category
        package_details = {
            "gaming": ["steam", "lutris", "gamemode", "mangohud", "discord"],
            "programming": ["git", "vscode", "gcc", "python3", "nodejs", "rust"],
            "multimedia": ["gimp", "kdenlive", "inkscape", "blender", "audacity"],
            "office": ["libreoffice", "thunderbird", "keepassxc", "nextcloud-client"],
            "daily": ["vlc", "telegram-desktop", "spotify"],
            "browser": ["firefox", "chromium"],
            "security": ["gnupg", "password-store", "yubikey-manager"],
            "networking": ["wireguard-tools", "openssh", "wireshark"],
            "virtualization": ["qemu", "virt-manager", "docker-compose"],
            "utils": ["ripgrep", "fd", "exa", "bat", "htop", "neofetch", "unzip"]
        }
        
        # Create a list of packages to install
        packages = []
        for category in selected_packages:
            if category in package_details:
                packages.extend(package_details[category])
        
        # Determine if we are using UEFI
        is_uefi = os.path.exists("/sys/firmware/efi")
        
        # Setup installation path
        config_dir = os.path.join(MOUNT_POINT, "etc/nixos")
        
        # Check if we should use the project structure
        if use_project_structure:
            # Create a configuration that imports the project's configuration
            configuration = f"""
# NixOS configuration generated by Bloom Nix installer
# This imports the desktop configuration from the Bloom Nix project

{{ config, pkgs, ... }}:

{{
  imports =
    [ # Include the results of the hardware scan
      ./hardware-configuration.nix
      
      # Import the desktop configuration from the Bloom Nix project
      ./bloom-nix/hosts/desktop
    ];

  # Basic system configuration
  networking.hostName = "{hostname}";
  time.timeZone = "{timezone}";
  i18n.defaultLocale = "{locale}";
  console.keyMap = "{keyboard}";

  # User account
  users.users.{username} = {{
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "{hash_password(password)}";
    home = "/home/{username}";
    description = "{fullname}";
  }};
  
  # Root account
  users.users.root.hashedPassword = {("\"" + hash_password(root_password) + "\"") if use_root else "null"};

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "24.05"; # Use appropriate version
}}
"""
        else:
            # Create a standalone configuration
            package_list = "\n      ".join([f"{pkg}" for pkg in packages])
            
            configuration = f"""
# NixOS configuration generated by Bloom Nix installer

{{ config, pkgs, ... }}:

{{
  imports =
    [ # Include the results of the hardware scan
      ./hardware-configuration.nix
    ];

  # Use the {'systemd-boot EFI' if is_uefi else 'GRUB'} boot loader
  {'boot.loader.systemd-boot.enable = true;\n  boot.loader.efi.canTouchEfiVariables = true;' if is_uefi else 'boot.loader.grub.enable = true;\n  boot.loader.grub.device = "/dev/sda";'}

  # Networking
  networking.hostName = "{hostname}";
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "{timezone}";

  # Select internationalisation properties
  i18n.defaultLocale = "{locale}";
  console.keyMap = "{keyboard}";

  # Enable KDE Plasma 6
  services.xserver.enable = true;
  services.xserver.layout = "{keyboard}";
  services.desktopManager.plasma6.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.wayland.enable = true;

  # Define a user account
  users.users.{username} = {{
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "{hash_password(password)}";
    home = "/home/{username}";
    description = "{fullname}";
  }};
  
  # Enable sudo access
  security.sudo.wheelNeedsPassword = true;
  
  # Enable or disable root account
  users.users.root.hashedPassword = {("\"" + hash_password(root_password) + "\"") if use_root else "null"};

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    vim
    wget
    git
    htop
    
    # Selected packages
    {package_list}
  ];

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support
  services.xserver.libinput.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # This is specific to the Bloom Nix distribution
  system.stateVersion = "24.05"; # Use appropriate version
}}
"""
        
        # Write the configuration to the file
        config_path = os.path.join(config_dir, "configuration.nix")
        with open(config_path, 'w') as f:
            f.write(configuration)
        
        logger.info("Successfully created system configuration")
        return True
    except Exception as e:
        logger.error(f"Error creating system configuration: {str(e)}")
        return False

def hash_password(password: str) -> str:
    """
    Hash a password using mkpasswd
    """
    try:
        # Use mkpasswd to hash the password
        result = subprocess.run(
            ["mkpasswd", "-m", "sha-512"],
            input=password.encode(),
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to hash password: {str(e)}")
        return ""
    except Exception as e:
        logger.error(f"Error hashing password: {str(e)}")
        return ""

def install_nixos() -> bool:
    """
    Install NixOS on the prepared system
    """
    logger.info("Installing NixOS")
    
    try:
        # Run nixos-install
        result = subprocess.run(
            ["nixos-install", "--root", MOUNT_POINT, "--no-root-passwd"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            logger.error(f"Failed to install NixOS: {result.stderr}")
            return False
        
        logger.info("Successfully installed NixOS")
        return True
    except Exception as e:
        logger.error(f"Error installing NixOS: {str(e)}")
        return False

def install_bootloader() -> bool:
    """
    Install the bootloader
    """
    logger.info("Installing bootloader")
    
    # The bootloader installation is handled by nixos-install
    # This function is mainly a placeholder for any additional bootloader configuration
    return True

def finalize_installation() -> bool:
    """
    Finalize the installation
    """
    logger.info("Finalizing installation")
    
    try:
        # Clean up
        # Unmount all filesystems
        subprocess.run(["umount", "-R", MOUNT_POINT], check=False)
        
        logger.info("Installation finalized")
        return True
    except Exception as e:
        logger.error(f"Error finalizing installation: {str(e)}")
        return False

def reboot() -> bool:
    """
    Reboot the system
    """
    logger.info("Rebooting system")
    
    try:
        # Reboot
        subprocess.run(["reboot"], check=False)
        return True
    except Exception as e:
        logger.error(f"Error rebooting system: {str(e)}")
        return False

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Bloom Nix Installer Sudo Helper")
    parser.add_argument("command", help="Command to execute")
    parser.add_argument("args", nargs="*", help="Command arguments")
    
    args = parser.parse_args()
    
    # Security: Check that the command is in the whitelist
    if args.command not in ALLOWED_COMMANDS:
        logger.error(f"Command not allowed: {args.command}")
        print(f"Command not allowed: {args.command}")
        sys.exit(1)
    
    # Execute the command
    if args.command == "list_disks":
        print(list_disks())
    
    elif args.command == "auto_partition_uefi":
        if len(args.args) < 1:
            logger.error("Missing disk path argument")
            sys.exit(1)
        
        if auto_partition_uefi(args.args[0]):
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "auto_partition_bios":
        if len(args.args) < 1:
            logger.error("Missing disk path argument")
            sys.exit(1)
        
        if auto_partition_bios(args.args[0]):
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "get_partition_info":
        if len(args.args) < 1:
            logger.error("Missing disk path argument")
            sys.exit(1)
        
        print(get_partition_info(args.args[0]))
    
    elif args.command == "launch_partitioning_tool":
        if len(args.args) < 1:
            logger.error("Missing disk path argument")
            sys.exit(1)
        
        if launch_partitioning_tool(args.args[0]):
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "mount_filesystems":
        if len(args.args) < 1:
            logger.error("Missing disk path argument")
            sys.exit(1)
        
        if mount_filesystems(args.args[0]):
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "generate_hardware_config":
        if generate_hardware_config():
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "copy_project_files":
        if copy_project_files():
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "create_system_config":
        if len(args.args) < 1:
            logger.error("Missing config file argument")
            sys.exit(1)
        
        if create_system_config(args.args[0]):
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "install_nixos":
        if install_nixos():
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "install_bootloader":
        if install_bootloader():
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "finalize_installation":
        if finalize_installation():
            print(json.dumps({"success": True}))
        else:
            print(json.dumps({"success": False}))
    
    elif args.command == "reboot":
        reboot()

if __name__ == "__main__":
    main()
