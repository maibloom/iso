#!/usr/bin/env python3
"""
Bloom Nix Installer - Minimal Sudo Helper
A lightweight helper script for privileged operations
"""

import os
import sys
import json
import subprocess
import re
import logging
import argparse

# Configure minimal logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    filename="/tmp/bloom-nix-installer-sudo.log"
)
logger = logging.getLogger("sudo-helper")

# Security: Validate script is run with sudo
if os.geteuid() != 0:
    print("This script must be run with sudo privileges.")
    sys.exit(1)

# Constants
MOUNT_POINT = "/mnt"

# Security: Whitelist of allowed commands
ALLOWED_COMMANDS = {
    "list_disks",
    "auto_partition_uefi",
    "auto_partition_bios",
    "launch_partitioning_tool",
    "mount_filesystems",
    "generate_hardware_config",
    "copy_project_files",
    "create_system_config",
    "install_nixos",
    "reboot"
}

# Validate disk path to prevent command injection
def validate_disk_path(disk_path):
    if not re.match(r"^/dev/[a-zA-Z0-9]+$", disk_path):
        return False
    if not os.path.exists(disk_path) or not os.path.isblock(disk_path):
        return False
    return True

# Command implementations
def list_disks():
    """Get available disks"""
    try:
        cmd = ["lsblk", "-dno", "NAME,SIZE,MODEL", "-e", "7,11"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            return json.dumps([])
        
        disks = []
        for line in result.stdout.splitlines():
            parts = line.strip().split(maxsplit=2)
            disk = {"name": parts[0], "size": parts[1]}
            if len(parts) > 2:
                disk["model"] = parts[2]
            else:
                disk["model"] = "Unknown"
            disks.append(disk)
        
        return json.dumps(disks)
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return json.dumps([])

def auto_partition_uefi(disk_path):
    """Automatically partition for UEFI"""
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Create GPT partition table
        subprocess.run(["parted", "-s", disk_path, "mklabel", "gpt"], check=True)
        
        # Create EFI partition (512MB)
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "fat32", "1MiB", "513MiB"], check=True)
        subprocess.run(["parted", "-s", disk_path, "set", "1", "esp", "on"], check=True)
        
        # Create root partition
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "ext4", "513MiB", "100%"], check=True)
        
        # Wait for partitions
        subprocess.run(["udevadm", "settle"], check=True)
        
        # Get partition devices
        disk_name = os.path.basename(disk_path)
        
        # Handle different disk naming
        if disk_name.startswith("nvme") or disk_name.startswith("mmcblk"):
            efi_part = f"{disk_path}p1"
            root_part = f"{disk_path}p2"
        else:
            efi_part = f"{disk_path}1"
            root_part = f"{disk_path}2"
        
        # Format partitions
        subprocess.run(["mkfs.fat", "-F32", efi_part], check=True)
        subprocess.run(["mkfs.ext4", "-F", root_part], check=True)
        
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def auto_partition_bios(disk_path):
    """Automatically partition for BIOS"""
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Create MBR partition table
        subprocess.run(["parted", "-s", disk_path, "mklabel", "msdos"], check=True)
        
        # Create BIOS boot partition (1MB)
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "1MiB", "2MiB"], check=True)
        subprocess.run(["parted", "-s", disk_path, "set", "1", "bios_grub", "on"], check=True)
        
        # Create root partition
        subprocess.run(["parted", "-s", disk_path, "mkpart", "primary", "ext4", "2MiB", "100%"], check=True)
        
        # Wait for partitions
        subprocess.run(["udevadm", "settle"], check=True)
        
        # Format root partition
        disk_name = os.path.basename(disk_path)
        
        if disk_name.startswith("nvme") or disk_name.startswith("mmcblk"):
            root_part = f"{disk_path}p2"
        else:
            root_part = f"{disk_path}2"
        
        subprocess.run(["mkfs.ext4", "-F", root_part], check=True)
        
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def launch_partitioning_tool(disk_path):
    """Launch partitioning tool"""
    if not validate_disk_path(disk_path):
        return False
    
    try:
        if os.path.exists("/usr/bin/gparted"):
            subprocess.Popen(["gparted", disk_path])
            return True
        elif os.path.exists("/usr/bin/cfdisk"):
            subprocess.run(["cfdisk", disk_path], check=True)
            return True
        else:
            return False
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def mount_filesystems(disk_path):
    """Mount filesystems for installation"""
    if not validate_disk_path(disk_path):
        return False
    
    try:
        # Get disk name
        disk_name = os.path.basename(disk_path)
        
        # Handle different naming schemes
        if disk_name.startswith("nvme") or disk_name.startswith("mmcblk"):
            root_part = f"{disk_path}p2"
            efi_part = f"{disk_path}p1"
        else:
            root_part = f"{disk_path}2"
            efi_part = f"{disk_path}1"
        
        # Create mount point
        os.makedirs(MOUNT_POINT, exist_ok=True)
        
        # Mount root filesystem
        subprocess.run(["mount", root_part, MOUNT_POINT], check=True)
        
        # Check for UEFI
        is_uefi = os.path.exists("/sys/firmware/efi")
        if is_uefi:
            os.makedirs(f"{MOUNT_POINT}/boot/efi", exist_ok=True)
            subprocess.run(["mount", efi_part, f"{MOUNT_POINT}/boot/efi"], check=True)
        
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def generate_hardware_config():
    """Generate NixOS hardware configuration"""
    try:
        subprocess.run(["nixos-generate-config", "--root", MOUNT_POINT], check=True)
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def copy_project_files():
    """Copy Bloom Nix project files"""
    try:
        # Create destination
        project_dir = os.path.join(MOUNT_POINT, "etc/nixos/bloom-nix")
        os.makedirs(project_dir, exist_ok=True)
        
        # Get environment variables
        project_root = os.environ.get("BLOOM_PROJECT_ROOT")
        if not project_root:
            return False
        
        # Copy modules
        for module in ["base", "desktop", "hardware", "packages", "branding"]:
            env_var = f"BLOOM_MODULE_{module.upper()}"
            module_path = os.environ.get(env_var)
            
            if module_path and os.path.exists(module_path):
                dest_dir = os.path.join(project_dir, "modules", module)
                os.makedirs(dest_dir, exist_ok=True)
                subprocess.run(["cp", "-r", f"{module_path}/.", dest_dir], check=True)
        
        # Copy host configuration
        host_config = os.environ.get("BLOOM_HOST_CONFIG")
        if host_config and os.path.exists(host_config):
            dest_dir = os.path.join(project_dir, "hosts/desktop")
            os.makedirs(dest_dir, exist_ok=True)
            subprocess.run(["cp", "-r", f"{host_config}/.", dest_dir], check=True)
        
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def create_system_config(config_file):
    """Create NixOS configuration"""
    try:
        # Load configuration
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        # Basic configuration template
        is_uefi = os.path.exists("/sys/firmware/efi")
        use_project = config.get('use_project_structure', False)
        
        if use_project:
            # Create configuration importing project files
            configuration = f"""
# Generated by Bloom Nix installer
{{ config, pkgs, ... }}:

{{
  imports = [
    ./hardware-configuration.nix
    ./bloom-nix/hosts/desktop
  ];

  networking.hostName = "{config.get('hostname', 'bloom-nix')}";
  users.users.{config.get('username', 'user')} = {{
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "{hash_password(config.get('password', ''))}";
    home = "/home/{config.get('username', 'user')}";
  }};

  system.stateVersion = "24.05";
}}
"""
        else:
            # Create standalone configuration
            configuration = f"""
# Generated by Bloom Nix installer
{{ config, pkgs, ... }}:

{{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader
  {'boot.loader.systemd-boot.enable = true;\n  boot.loader.efi.canTouchEfiVariables = true;' if is_uefi else 'boot.loader.grub.enable = true;\n  boot.loader.grub.device = "/dev/sda";'}

  # Basic settings
  networking.hostName = "{config.get('hostname', 'bloom-nix')}";
  networking.networkmanager.enable = true;
  time.timeZone = "{config.get('timezone', 'America/New_York')}";
  i18n.defaultLocale = "{config.get('locale', 'en_US.UTF-8')}";

  # Desktop environment
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.wayland.enable = true;

  # User account
  users.users.{config.get('username', 'user')} = {{
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "{hash_password(config.get('password', ''))}";
    home = "/home/{config.get('username', 'user')}";
  }};

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}}
"""
        
        # Write configuration
        config_path = os.path.join(MOUNT_POINT, "etc/nixos/configuration.nix")
        with open(config_path, 'w') as f:
            f.write(configuration)
        
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def hash_password(password):
    """Hash password using mkpasswd"""
    try:
        result = subprocess.run(
            ["mkpasswd", "-m", "sha-512"],
            input=password.encode(),
            capture_output=True,
            text=True
        )
        return result.stdout.strip()
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return ""

def install_nixos():
    """Install NixOS"""
    try:
        subprocess.run(["nixos-install", "--root", MOUNT_POINT, "--no-root-passwd"], check=True)
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def reboot():
    """Reboot the system"""
    try:
        subprocess.run(["reboot"], check=False)
        return True
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return False

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Bloom Nix Installer Sudo Helper")
    parser.add_argument("command", help="Command to execute")
    parser.add_argument("args", nargs="*", help="Command arguments")
    args = parser.parse_args()
    
    # Security: Check if command is allowed
    if args.command not in ALLOWED_COMMANDS:
        print(json.dumps({"error": "Command not allowed"}))
        sys.exit(1)
    
    # Execute the command
    if args.command == "list_disks":
        print(list_disks())
    
    elif args.command == "auto_partition_uefi":
        if len(args.args) < 1:
            print(json.dumps({"error": "Missing disk path"}))
            sys.exit(1)
        
        result = auto_partition_uefi(args.args[0])
        print(json.dumps({"success": result}))
    
    elif args.command == "auto_partition_bios":
        if len(args.args) < 1:
            print(json.dumps({"error": "Missing disk path"}))
            sys.exit(1)
        
        result = auto_partition_bios(args.args[0])
        print(json.dumps({"success": result}))
    
    elif args.command == "launch_partitioning_tool":
        if len(args.args) < 1:
            print(json.dumps({"error": "Missing disk path"}))
            sys.exit(1)
        
        result = launch_partitioning_tool(args.args[0])
        print(json.dumps({"success": result}))
    
    elif args.command == "mount_filesystems":
        if len(args.args) < 1:
            print(json.dumps({"error": "Missing disk path"}))
            sys.exit(1)
        
        result = mount_filesystems(args.args[0])
        print(json.dumps({"success": result}))
    
    elif args.command == "generate_hardware_config":
        result = generate_hardware_config()
        print(json.dumps({"success": result}))
    
    elif args.command == "copy_project_files":
        result = copy_project_files()
        print(json.dumps({"success": result}))
    
    elif args.command == "create_system_config":
        if len(args.args) < 1:
            print(json.dumps({"error": "Missing config file"}))
            sys.exit(1)
        
        result = create_system_config(args.args[0])
        print(json.dumps({"success": result}))
    
    elif args.command == "install_nixos":
        result = install_nixos()
        print(json.dumps({"success": result}))
    
    elif args.command == "reboot":
        reboot()

if __name__ == "__main__":
    main()
