#!/usr/bin/env python3
"""
Bloom Nix Installer - Minimal Sudo Helper
This script is a compatibility layer that allows executing privileged commands.
With the declarative approach, this is much simpler than the previous version.
"""

import sys
import subprocess
import os
import json

def list_disks():
    """List available disks with their details"""
    try:
        # Use lsblk to get disk information
        result = subprocess.run(
            ["lsblk", "-d", "-o", "NAME,SIZE,MODEL", "-J"],
            capture_output=True,
            text=True
        )
        
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

def run_flake_install(flake_path, hostname):
    """Run NixOS installation using a flake configuration"""
    try:
        # Run the installation command
        install_cmd = ["nixos-install", "--no-root-passwd", "--flake", f"{flake_path}#{hostname}"]
        
        result = subprocess.run(
            install_cmd,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            sys.stderr.write(f"Error installing NixOS: {result.stderr}\n")
            return False
        
        print("NixOS installation completed successfully")
        return True
    except Exception as e:
        sys.stderr.write(f"Error running installation: {str(e)}\n")
        return False

def reboot():
    """Reboot the system"""
    try:
        subprocess.run(["reboot"])
        return "Rebooting..."
    except Exception as e:
        sys.stderr.write(f"Error rebooting: {str(e)}\n")
        return "Failed to reboot"

def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Error: No command specified\n")
        sys.exit(1)
    
    command = sys.argv[1]
    
    # Handle different commands
    if command == "list_disks":
        print(list_disks())
    elif command == "flake_install" and len(sys.argv) > 3:
        success = run_flake_install(sys.argv[2], sys.argv[3])
        if not success:
            sys.exit(1)
    elif command == "run_command" and len(sys.argv) > 2:
        # Run an arbitrary command (be careful with this)
        # Example: sudo-helper.py run_command "command args"
        try:
            cmd = sys.argv[2]
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if result.returncode != 0:
                sys.stderr.write(result.stderr)
                sys.exit(1)
            print(result.stdout)
        except Exception as e:
            sys.stderr.write(f"Error running command: {str(e)}\n")
            sys.exit(1)
    elif command == "reboot":
        print(reboot())
    else:
        sys.stderr.write(f"Error: Unknown command '{command}'\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
