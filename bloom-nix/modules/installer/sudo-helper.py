#!/usr/bin/env python3
"""
Bloom Nix Installer - Sudo Helper
This script runs operations that require root privileges.
"""

import sys
import json
import subprocess
import os
import time
import re
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
        
        # Filter out loop devices and other non-disk devices
        formatted_disks = []
        for disk in disks_data.get('blockdevices', []):
            name = disk['name']
            # Skip loop devices, ram disks, and cdrom devices
            if (not name.startswith('loop') and 
                not name.startswith('ram') and 
                not name.startswith('sr')):
                formatted_disks.append({
                    'name': name,
                    'size': disk.get('size', 'Unknown'),
                    'model': disk.get('model', 'Unknown').strip()
                })
        
        return json.dumps(formatted_disks)
    except Exception as e:
        sys.stderr.write(f"Error listing disks: {str(e)}\n")
        return json.dumps([])

def is_disk_in_use(disk):
    """Check if disk is currently in use (mounted or has active swap)"""
    device = f"/dev/{disk}"
    
    # Check if the disk or any of its partitions are mounted
    try:
        mount_result = subprocess.run(["mount"], capture_output=True, text=True)
        if device in mount_result.stdout:
            return True
        
        # Check for device with partition numbers (both traditional and nvme style)
        nvme_style = re.search(r'^nvme\d+n\d+$|^mmcblk\d+$', disk)
        if nvme_style:
            # NVMe or MMC devices use p1, p2, etc.
            pattern = f"{re.escape(device)}p\\d+"
        else:
            # Traditional drives use 1, 2, etc.
            pattern = f"{re.escape(device)}\\d+"
            
        if re.search(pattern, mount_result.stdout):
            return True
    except Exception:
        # If we can't determine, assume it's safer to say it's in use
        return True
    
    # Check for active swap on this device
    try:
        swap_result = subprocess.run(["swapon", "--show"], capture_output=True, text=True)
        if device in swap_result.stdout:
            return True
    except Exception:
        pass
    
    return False

def unmount_all_partitions(disk):
    """Safely unmount all partitions of a disk"""
    device = f"/dev/{disk}"
    
    # Turn off swap on this device first
    try:
        nvme_style = re.search(r'^nvme\d+n\d+$|^mmcblk\d+$', disk)
        if nvme_style:
            # NVMe or MMC devices
            swap_pattern = f"{device}p*"
        else:
            # Traditional drives
            swap_pattern = f"{device}*"
            
        subprocess.run(["swapoff", swap_pattern], stderr=subprocess.DEVNULL, check=False)
    except Exception:
        pass
    
    # Unmount all partitions (both traditional and nvme style)
    try:
        # This attempts to unmount all partitions in one go
        subprocess.run(f"umount {device}* 2>/dev/null || true", shell=True, check=False)
        
        # For stubborn mounts, try individual partitions with -l (lazy unmount)
        mount_output = subprocess.run(["mount"], capture_output=True, text=True).stdout
        partitions = []
        
        nvme_style = re.search(r'^nvme\d+n\d+$|^mmcblk\d+$', disk)
        if nvme_style:
            # NVMe or MMC devices use p1, p2, etc.
            pattern = f"{re.escape(device)}p\\d+"
        else:
            # Traditional drives use 1, 2, etc.
            pattern = f"{re.escape(device)}\\d+"
            
        for line in mount_output.splitlines():
            match = re.search(pattern, line)
            if match:
                partitions.append(match.group(0))
        
        # Unmount each partition with -l (lazy)
        for partition in partitions:
            subprocess.run(["umount", "-l", partition], stderr=subprocess.DEVNULL, check=False)
        
        # Small delay to let unmounts complete
        time.sleep(1)
        
        # Verify unmount was successful
        after_mount = subprocess.run(["mount"], capture_output=True, text=True).stdout
        return not any(re.search(pattern, after_mount) for line in after_mount.splitlines())
    except Exception as e:
        sys.stderr.write(f"Warning: Unmount error - {str(e)}\n")
        return False

def get_partition_prefix(disk):
    """Determine the partition prefix for a given disk"""
    # NVMe drives (nvme0n1), MMC devices (mmcblk0), and some others use 'p' before the number
    if re.match(r'^nvme\d+n\d+$|^mmcblk\d+$', disk):
        return 'p'
    # Traditional drives (sda, vda, hda, etc.) have no prefix
    return ''

def partition_disk(disk):
    """Automatically partition the disk with enhanced safety and logging"""
    try:
        device = f"/dev/{disk}"
        efi_boot = os.path.exists('/sys/firmware/efi')
        
        # Check if disk exists
        if not os.path.exists(device):
            sys.stderr.write(f"Error: Disk {device} not found\n")
            sys.exit(1)
        
        # Check disk size (must be at least 5GB)
        try:
            size_bytes = int(open(f"/sys/block/{disk}/size").read().strip()) * 512  # sector size * num sectors
            min_size = 5 * 1024 * 1024 * 1024  # 5GB in bytes
            if size_bytes < min_size:
                sys.stderr.write(f"Error: Disk {device} is too small ({size_bytes / (1024**3):.1f} GB). Minimum 5GB required.\n")
                sys.exit(1)
        except Exception as e:
            sys.stderr.write(f"Warning: Could not check disk size: {str(e)}\n")
        
        # Check if disk is in use and try to unmount
        if is_disk_in_use(disk):
            sys.stderr.write(f"Disk {device} is in use. Attempting to unmount...\n")
            if not unmount_all_partitions(disk):
                sys.stderr.write(f"Error: Failed to unmount {device}. Disk may be in use.\n")
                sys.exit(1)
        
        # Get the correct partition prefix (empty or 'p')
        part_prefix = get_partition_prefix(disk)
        
        # Clear existing partition table with extra safety
        sys.stderr.write(f"Clearing partition table on {device}...\n")
        
        # Try multiple methods to ensure the partition table is cleared
        try:
            # First zero out the first few MB of the disk to remove any remnants
            subprocess.run(["dd", "if=/dev/zero", f"of={device}", "bs=1M", "count=10"], 
                          stderr=subprocess.DEVNULL, check=False)
            # Use wipefs to clear known signatures
            subprocess.run(["wipefs", "-a", device], check=True)
        except Exception as e:
            sys.stderr.write(f"Warning during disk clearing: {str(e)}\n")
            # Continue anyway as parted will create a new partition table
        
        # Create new partition table
        if efi_boot:
            # GPT for UEFI
            sys.stderr.write(f"Creating GPT partition table for UEFI boot...\n")
            subprocess.run(["parted", "-s", device, "mklabel", "gpt"], check=True)
            
            # Create EFI boot partition (512MB)
            sys.stderr.write(f"Creating EFI boot partition...\n")
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "ESP", "fat32", "1MiB", "513MiB",
                "set", "1", "boot", "on"
            ], check=True)
            
            # Create root partition
            sys.stderr.write(f"Creating root partition...\n")
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "primary", "513MiB", "100%"
            ], check=True)
            
            # Wait for the kernel to recognize the new partitions
            sys.stderr.write("Waiting for partitions to be recognized...\n")
            time.sleep(3)
            
            # Determine partition device names
            part1 = f"{device}{part_prefix}1"
            part2 = f"{device}{part_prefix}2"
            
            # Verify partitions exist
            if not os.path.exists(part1) or not os.path.exists(part2):
                # Wait longer and check again
                time.sleep(5)
                if not os.path.exists(part1) or not os.path.exists(part2):
                    sys.stderr.write(f"Error: Partitions {part1} and {part2} were not created correctly\n")
                    sys.exit(1)
            
            # Format EFI partition with extra safety
            sys.stderr.write(f"Formatting EFI partition {part1}...\n")
            try:
                subprocess.run(["mkfs.fat", "-F", "32", part1], check=True)
            except Exception as e:
                sys.stderr.write(f"Error formatting EFI partition: {str(e)}\n")
                sys.exit(1)
            
            # Format root partition with extra safety
            sys.stderr.write(f"Formatting root partition {part2}...\n")
            try:
                # Force format to avoid confirmation prompts
                subprocess.run(["mkfs.ext4", "-F", part2], check=True)
            except Exception as e:
                sys.stderr.write(f"Error formatting root partition: {str(e)}\n")
                sys.exit(1)
            
            # Create mount points
            sys.stderr.write("Creating mount points...\n")
            os.makedirs("/mnt", exist_ok=True)
            os.makedirs("/mnt/boot", exist_ok=True)
            
            # Mount partitions
            sys.stderr.write(f"Mounting {part2} to /mnt...\n")
            try:
                subprocess.run(["mount", part2, "/mnt"], check=True)
            except Exception as e:
                sys.stderr.write(f"Error mounting root partition: {str(e)}\n")
                sys.exit(1)
            
            sys.stderr.write(f"Mounting {part1} to /mnt/boot...\n")
            try:
                subprocess.run(["mount", part1, "/mnt/boot"], check=True)
            except Exception as e:
                sys.stderr.write(f"Error mounting boot partition: {str(e)}\n")
                # Unmount root in case of failure
                subprocess.run(["umount", "/mnt"], check=False)
                sys.exit(1)
        else:
            # MBR for BIOS
            sys.stderr.write(f"Creating MBR partition table for BIOS boot...\n")
            subprocess.run(["parted", "-s", device, "mklabel", "msdos"], check=True)
            
            # Create boot partition (512MB)
            sys.stderr.write(f"Creating boot partition...\n")
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "primary", "1MiB", "513MiB",
                "set", "1", "boot", "on"
            ], check=True)
            
            # Create root partition
            sys.stderr.write(f"Creating root partition...\n")
            subprocess.run([
                "parted", "-s", device,
                "mkpart", "primary", "513MiB", "100%"
            ], check=True)
            
            # Wait for the kernel to recognize the new partitions
            sys.stderr.write("Waiting for partitions to be recognized...\n")
            time.sleep(3)
            
            # Determine partition device names
            part1 = f"{device}{part_prefix}1"
            part2 = f"{device}{part_prefix}2"
            
            # Verify partitions exist
            if not os.path.exists(part1) or not os.path.exists(part2):
                # Wait longer and check again
                time.sleep(5)
                if not os.path.exists(part1) or not os.path.exists(part2):
                    sys.stderr.write(f"Error: Partitions {part1} and {part2} were not created correctly\n")
                    sys.exit(1)
            
            # Format boot partition with extra safety
            sys.stderr.write(f"Formatting boot partition {part1}...\n")
            try:
                subprocess.run(["mkfs.ext4", "-F", part1], check=True)
            except Exception as e:
                sys.stderr.write(f"Error formatting boot partition: {str(e)}\n")
                sys.exit(1)
            
            # Format root partition with extra safety
            sys.stderr.write(f"Formatting root partition {part2}...\n")
            try:
                subprocess.run(["mkfs.ext4", "-F", part2], check=True)
            except Exception as e:
                sys.stderr.write(f"Error formatting root partition: {str(e)}\n")
                sys.exit(1)
            
            # Create mount points
            sys.stderr.write("Creating mount points...\n")
            os.makedirs("/mnt", exist_ok=True)
            os.makedirs("/mnt/boot", exist_ok=True)
            
            # Mount partitions
            sys.stderr.write(f"Mounting {part2} to /mnt...\n")
            try:
                subprocess.run(["mount", part2, "/mnt"], check=True)
            except Exception as e:
                sys.stderr.write(f"Error mounting root partition: {str(e)}\n")
                sys.exit(1)
            
            sys.stderr.write(f"Mounting {part1} to /mnt/boot...\n")
            try:
                subprocess.run(["mount", part1, "/mnt/boot"], check=True)
            except Exception as e:
                sys.stderr.write(f"Error mounting boot partition: {str(e)}\n")
                # Unmount root in case of failure
                subprocess.run(["umount", "/mnt"], check=False)
                sys.exit(1)
        
        # Verify mounts are successful
        mount_result = subprocess.run(["mount"], capture_output=True, text=True)
        if f"{part2} on /mnt" not in mount_result.stdout or f"{part1} on /mnt/boot" not in mount_result.stdout:
            sys.stderr.write("Error: Mounts not found in mount table. Partitioning may have failed.\n")
            sys.exit(1)
        
        sys.stderr.write("Disk partitioning completed successfully.\n")
        return "Disk partitioned successfully"
    except Exception as e:
        sys.stderr.write(f"Error partitioning disk: {str(e)}\n")
        # Try to clean up if something went wrong
        try:
            subprocess.run(["umount", "/mnt/boot"], check=False)
            subprocess.run(["umount", "/mnt"], check=False)
        except:
            pass
        sys.exit(1)

def generate_hardware_config(target_dir, disk):
    """Generate NixOS hardware configuration"""
    try:
        # Ensure target directory exists
        os.makedirs(target_dir, exist_ok=True)
        
        # Run nixos-generate-config to create hardware-configuration.nix
        sys.stderr.write(f"Generating hardware configuration...\n")
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
        
        sys.stderr.write("Hardware configuration generated successfully.\n")
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
            sys.stderr.write(f"Installing NixOS with flake configuration...\n")
            install_cmd = ["nixos-install", "--no-root-passwd"]
            if hostname:
                install_cmd.extend(["--flake", f"/mnt/etc/nixos#{hostname}"])
                sys.stderr.write(f"Using flake /mnt/etc/nixos#{hostname}\n")
            else:
                install_cmd.extend(["--flake", "/mnt/etc/nixos"])
                sys.stderr.write(f"Using flake /mnt/etc/nixos\n")
                
            sys.stderr.write(f"Running command: {' '.join(install_cmd)}\n")
            result = subprocess.run(install_cmd, capture_output=True, text=True)
        else:
            # Traditional installation
            sys.stderr.write(f"Installing NixOS with traditional configuration...\n")
            result = subprocess.run(
                ["nixos-install", "--no-root-passwd"],
                capture_output=True,
                text=True
            )
        
        if result.returncode != 0:
            sys.stderr.write(f"Error installing NixOS: {result.stderr}\n")
            sys.exit(1)
        
        sys.stderr.write("NixOS installed successfully.\n")
        return "NixOS installed successfully"
    except Exception as e:
        sys.stderr.write(f"Error installing NixOS: {str(e)}\n")
        sys.exit(1)

def set_password(username, password):
    """Set user password"""
    try:
        # Use chpasswd to set the password
        sys.stderr.write(f"Setting password for user {username}...\n")
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
        
        sys.stderr.write("Password set successfully.\n")
        return "Password set successfully"
    except Exception as e:
        sys.stderr.write(f"Error setting password: {str(e)}\n")
        sys.exit(1)

def reboot():
    """Reboot the system"""
    sys.stderr.write("Rebooting system...\n")
    subprocess.run(["reboot"])
    return "Rebooting..."

def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Error: No command specified\n")
        sys.exit(1)
    
    command = sys.argv[1]
    
    # Handle different commands
    try:
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
    except Exception as e:
        sys.stderr.write(f"Unhandled error in sudo-helper: {str(e)}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
