#!/usr/bin/env python3
"""
Bloom Nix Installer - Sudo Helper (Simple Version)
This script runs operations that require root privileges.
"""

import sys
import json
import subprocess
import os
from pathlib import Path

def list_disks():
    """List available disks with their details"""
    try:
        # Get list of disk devices using lsblk
        lsblk_cmd = ["lsblk", "-d", "-o", "NAME,SIZE,MODEL", "-J"]
        result = subprocess.run(lsblk_cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return json.dumps([])
        
        # Parse the JSON output
        disks_data = json.loads(result.stdout)
        
        # Filter out loop devices
        formatted_disks = []
        for disk in disks_data.get('blockdevices', []):
            if not disk['name'].startswith('loop'):
                formatted_disks.append({
                    'name': disk['name'],
                    'size': disk.get('size', 'Unknown'),
                    'model': disk.get('model', 'Unknown').strip()
                })
        
        return json.dumps(formatted_disks)
    except Exception as e:
        sys.stderr.write(f"Error listing disks: {str(e)}\n")
        return json.dumps([])

def partition_disk(disk):
    """Automatically partition the disk"""
    try:
        device = f"/dev/{disk}"
        efi_boot = os.path.exists('/sys/firmware/efi')
        
        # Clear existing partition table
        subprocess.run(["wipefs", "-a", device], check=True)
        
        # Create new partition table
        if efi_boot:
            # GPT for UEFI
            subprocess.run(["parted", "-s", device, "mklabel", "gpt"], check=True)
            
            # Create EFI boot partition (512MB)
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "ESP", "fat32", "1MiB", "513MiB",
                "set", "1", "boot", "on"
            ], check=True)
            
            # Create root partition
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "primary", "513MiB", "100%"
            ], check=True)
            
            # Format EFI partition
            subprocess.run(["mkfs.fat", "-F32", f"{device}1"], check=True)
            
            # Format root partition
            subprocess.run(["mkfs.ext4", f"{device}2"], check=True)
            
            # Mount partitions
            os.makedirs("/mnt/boot", exist_ok=True)
            subprocess.run(["mount", f"{device}2", "/mnt"], check=True)
            subprocess.run(["mount", f"{device}1", "/mnt/boot"], check=True)
        else:
            # MBR for BIOS
            subprocess.run(["parted", "-s", device, "mklabel", "msdos"], check=True)
            
            # Create boot partition (512MB)
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "primary", "1MiB", "513MiB",
                "set", "1", "boot", "on"
            ], check=True)
            
            # Create root partition
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "primary", "513MiB", "100%"
            ], check=True)
            
            # Format boot partition
            subprocess.run(["mkfs.ext4", f"{device}1"], check=True)
            
            # Format root partition
            subprocess.run(["mkfs.ext4", f"{device}2"], check=True)
            
            # Mount partitions
            os.makedirs("/mnt/boot", exist_ok=True)
            subprocess.run(["mount", f"{device}2", "/mnt"], check=True)
            subprocess.run(["mount", f"{device}1", "/mnt/boot"], check=True)
        
        return "Disk partitioned successfully"
    except Exception as e:
        sys.stderr.write(f"Error partitioning disk: {str(e)}\n")
        sys.exit(1)

def generate_hardware_config(target_dir, disk):
    """Generate NixOS hardware configuration"""
    try:
        # Ensure target directory exists
        os.makedirs(target_dir, exist_ok=True)
        
        # Run nixos-generate-config to create hardware-configuration.nix
        result = subprocess.run(
            ["nixos-generate-config", "--root", "/mnt", "--show-hardware-config"],
            capture_output=True, 
            text=True
        )
        
        if result.returncode != 0:
            sys.stderr.write(f"Error generating hardware config: {result.stderr}\n")
            sys.exit(1)
        
        # Write the hardware configuration to a file
        with open(f"{target_dir}/hardware-configuration.nix", "w") as f:
            f.write(result.stdout)
        
        return "Hardware configuration generated successfully"
    except Exception as e:
        sys.stderr.write(f"Error generating hardware config: {str(e)}\n")
        sys.exit(1)

def install_system():
    """Run the NixOS installer"""
    try:
        # Check if we're using a flake-based install
        if os.path.exists("/mnt/etc/nixos/flake.nix"):
            # Try to determine hostname from flake
            hostname = None
            try:
                with open("/mnt/etc/nixos/flake.nix", "r") as f:
                    flake_content = f.read()
                    import re
                    hostname_match = re.search(r'nixosConfigurations\.(\w+)\s*=', flake_content)
                    if hostname_match:
                        hostname = hostname_match.group(1)
            except:
                pass
            
            # Run installation with flake
            install_cmd = ["nixos-install", "--no-root-passwd"]
            if hostname:
                install_cmd.extend(["--flake", f"/mnt/etc/nixos#{hostname}"])
            else:
                install_cmd.extend(["--flake", "/mnt/etc/nixos"])
                
            result = subprocess.run(install_cmd, capture_output=True, text=True)
        else:
            # Traditional installation
            result = subprocess.run(
                ["nixos-install", "--no-root-passwd"],
                capture_output=True,
                text=True
            )
        
        if result.returncode != 0:
            sys.stderr.write(f"Error installing NixOS: {result.stderr}\n")
            sys.exit(1)
        
        return "NixOS installed successfully"
    except Exception as e:
        sys.stderr.write(f"Error installing NixOS: {str(e)}\n")
        sys.exit(1)

def set_password(username, password):
    """Set user password"""
    try:
        # Use chpasswd to set the password
        proc = subprocess.Popen(
            ["chpasswd", "-R", "/mnt"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, stderr = proc.communicate(f"{username}:{password}")
        
        if proc.returncode != 0:
            sys.stderr.write(f"Error setting password: {stderr}\n")
            sys.exit(1)
        
        return "Password set successfully"
    except Exception as e:
        sys.stderr.write(f"Error setting password: {str(e)}\n")
        sys.exit(1)

def reboot():
    """Reboot the system"""
    subprocess.run(["reboot"])
    return "Rebooting..."

def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Error: No command specified\n")
        sys.exit(1)
    
    command = sys.argv[1]
    
    # Handle different commands
    if command == "list_disks":
        print(list_disks())
    elif command == "partition_disk" and len(sys.argv) > 2:
        print(partition_disk(sys.argv[2]))
    elif command == "generate_hardware_config" and len(sys.argv) > 3:
        print(generate_hardware_config(sys.argv[2], sys.argv[3]))
    elif command == "install_system":
        print(install_system())
    elif command == "set_password" and len(sys.argv) > 3:
        print(set_password(sys.argv[2], sys.argv[3]))
    elif command == "reboot":
        print(reboot())
    else:
        sys.stderr.write(f"Error: Unknown command '{command}'\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
