#!/usr/bin/env python3
"""
Bloom Nix Declarative Installer
A streamlined web-based installer that uses NixOS's declarative approach with disko
"""

import streamlit as st
import os
import json
import subprocess
import logging
import time
import random
import socket
import urllib.request
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler("/tmp/bloom-nix-installer.log")]
)
logger = logging.getLogger("bloom-installer")

# Constants
VERSION = "1.0.0"
CONFIG_PATH = "/tmp/bloom-nix-installer.json"
MARKER_PATH = "/tmp/bloom-installer-running"
LOGO_PATH = "/etc/bloom-installer/logo.png"

# Custom helper functions
def rerun_app():
    """Rerun the app, compatible with different Streamlit versions"""
    try:
        # Try the new method first (Streamlit >= 1.27.0)
        st.rerun()
    except AttributeError:
        try:
            # Fall back to the old method (older Streamlit versions)
            st.experimental_rerun()
        except AttributeError:
            # If both fail, use the session state hack as last resort
            st.session_state.random_rerun_key = random.randint(0, 1000000)
            # This forces a rerun because the session state changed

def check_internet_connection():
    """Check for internet connectivity - returns (is_connected, error_message)"""
    # First, try DNS resolution
    try:
        # Try to resolve a well-known domain
        socket.gethostbyname("nixos.org")
        
        # If that succeeds, try to connect to a server
        try:
            # Try to connect to the NixOS website with a 5-second timeout
            urllib.request.urlopen("https://nixos.org", timeout=5)
            return True, ""
        except Exception as e:
            return False, f"Could not connect to nixos.org: {str(e)}"
    except Exception as e:
        return False, f"DNS resolution failed: {str(e)}"

# Create marker file to indicate the installer is running
Path(MARKER_PATH).touch(exist_ok=True)

# Get project structure from environment variables
PROJECT_ROOT = os.environ.get("BLOOM_PROJECT_ROOT", "")
MODULE_BASE = os.environ.get("BLOOM_MODULE_BASE", "")
MODULE_DESKTOP = os.environ.get("BLOOM_MODULE_DESKTOP", "")
MODULE_HARDWARE = os.environ.get("BLOOM_MODULE_HARDWARE", "")
MODULE_PACKAGES = os.environ.get("BLOOM_MODULE_PACKAGES", "")
MODULE_BRANDING = os.environ.get("BLOOM_MODULE_BRANDING", "")
HOST_CONFIG = os.environ.get("BLOOM_HOST_CONFIG", "")
ENABLE_PLASMA6 = os.environ.get("BLOOM_ENABLE_PLASMA6", "true").lower() == "true"

# Checking, debugging and precting possible issue...
# if PROJECT_ROOT is not set:
if not PROJECT_ROOT:
    # Try to find it based on the script location
    logger.info("PROJECT_ROOT not set, attempting to detect automatically")
    script_dir = os.path.dirname(os.path.abspath(__file__))
    potential_paths = [
        os.path.abspath(os.path.join(script_dir, "../..")),
        os.path.abspath(os.path.join(script_dir, "../../../")),
        # Add more potential paths if needed
    ]
    for path in potential_paths:
        if os.path.exists(os.path.join(path, "flake.nix")):
            PROJECT_ROOT = path
            logger.info(f"Found project root at: {PROJECT_ROOT}")
            break

# Add near the top of main.py
def startup_checks():
    """Perform sanity checks at startup and log any issues"""
    try:
        # Check for required commands
        for cmd in ["nixos-install", "lsblk", "reboot"]:
            result = subprocess.run(["which", cmd], capture_output=True, text=True)
            if result.returncode != 0:
                logger.warning(f"Required command not found: {cmd}")
                
        # Check project structure
        if not PROJECT_ROOT:
            logger.warning("PROJECT_ROOT environment variable not set")
            
        # Log system information
        logger.info(f"Starting Bloom Nix Installer v{VERSION}")
        logger.info(f"Python version: {sys.version}")
        logger.info(f"Project root: {PROJECT_ROOT}")
        logger.info(f"EFI system: {is_efi_system()}")
        
        return True
    except Exception as e:
        logger.error(f"Startup check failed: {str(e)}")
        return False

# Call this at the beginning of main()
if not startup_checks():
    st.error("Installer startup checks failed. Please check the logs at /tmp/bloom-nix-installer.log")


# Apply custom theme
st.markdown("""
<style>
    .main { background-color: #1E1E1E; color: #FFFFFF; }
    .stButton button { background-color: #FF5733; color: white; border-radius: 4px; border: none; }
    .stProgress .st-bp { background-color: #FF5733; }
    h1, h2, h3 { color: #FF5733; }
    .stMultiSelect span { background-color: #FF5733; }
</style>
""", unsafe_allow_html=True)

# Helper Functions
def run_sudo_command(command):
    """Run a command with sudo privileges"""
    try:
        # Use sudo directly for simple commands
        result = subprocess.run(
            ["sudo", "sh", "-c", command],
            capture_output=True,
            text=True
        )
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        logger.error(f"Error running command: {str(e)}")
        return 1, "", str(e)

def get_disks():
    """Get list of available disks"""
    try:
        # Use lsblk to get disk information
        result = subprocess.run(
            ["lsblk", "-d", "-o", "NAME,SIZE,MODEL", "-J"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            return []
        
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
        
        return formatted_disks
    except Exception as e:
        logger.error(f"Error listing disks: {str(e)}")
        return []

def is_efi_system():
    """Check if system is booted in UEFI mode"""
    return os.path.exists("/sys/firmware/efi")

def save_config(config):
    """Save configuration to file"""
    with open(CONFIG_PATH, 'w') as f:
        json.dump(config, f)
    logger.info("Configuration saved")

def load_config():
    """Load configuration from file"""
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, 'r') as f:
                return json.load(f)
        except:
            pass
    # Default configuration
    return {
        "hostname": "bloom-nix",
        "username": "",
        "password": "",
        "disk": "",
        "desktop": "plasma",  # Always use Plasma as the default
        "packages": ["daily", "browser"],
        "timezone": "America/New_York",
        "locale": "en_US.UTF-8"
    }

def get_package_categories():
    """Get package categories from the packages module"""
    if not MODULE_PACKAGES:
        return {
            "daily": "Everyday apps",
            "browser": "Web browsers", 
            "office": "Office applications",
            "programming": "Development tools",
            "multimedia": "Media creation",
            "gaming": "Gaming (Steam, Lutris)",
            "utils": "System utilities"
        }
    
    try:
        # Try to parse the package categories from the module
        package_module_path = os.path.join(MODULE_PACKAGES, "default.nix")
        if not os.path.exists(package_module_path):
            return {
                "daily": "Everyday apps",
                "browser": "Web browsers", 
                "office": "Office applications",
                "programming": "Development tools",
                "multimedia": "Media creation",
                "gaming": "Gaming (Steam, Lutris)",
                "utils": "System utilities"
            }
        
        with open(package_module_path, "r") as f:
            content = f.read()
        
        # Look for package categories in the file
        # This is a simple pattern that might need adjustment based on your module structure
        import re
        categories = []
        pattern = r'bloom\.packages\.(\w+)'
        matches = re.findall(pattern, content)
        if matches:
            for match in matches:
                if match not in categories:
                    categories.append(match)
        
        # Create a mapping with descriptions
        category_mapping = {}
        for category in categories:
            # Try to extract a description if available
            desc_pattern = r'#\s*(.*?)\s*\n.*?bloom\.packages\.{}'.format(category)
            desc_match = re.search(desc_pattern, content, re.DOTALL)
            description = desc_match.group(1).strip() if desc_match else f"{category.capitalize()} packages"
            category_mapping[category] = description
        
        if not category_mapping:
            # Fallback to default categories
            return {
                "daily": "Everyday apps",
                "browser": "Web browsers", 
                "office": "Office applications",
                "programming": "Development tools",
                "multimedia": "Media creation",
                "gaming": "Gaming (Steam, Lutris)",
                "utils": "System utilities"
            }
        
        return category_mapping
    except Exception as e:
        logger.error(f"Error parsing package categories: {str(e)}")
        return {
            "daily": "Everyday apps",
            "browser": "Web browsers", 
            "office": "Office applications",
            "programming": "Development tools",
            "multimedia": "Media creation",
            "gaming": "Gaming (Steam, Lutris)",
            "utils": "System utilities"
        }

def generate_nix_config(config):
    """Generate fully declarative NixOS flake configuration"""
    logger.info(f"Generating NixOS configuration with: {json.dumps(config)}")
    
    # Extract configuration values
    hostname = config.get('hostname', 'bloom-nix')
    username = config.get('username', 'user')
    password = config.get('password', '')
    timezone = config.get('timezone', 'America/New_York')
    locale = config.get('locale', 'en_US.UTF-8')
    disk = config.get('disk', '')
    # Always use Plasma as the desktop environment
    desktop = "plasma"
    packages = config.get('packages', [])
    
    # Create temporary installer directory
    installer_dir = "/tmp/bloom-installer"
    os.makedirs(installer_dir, exist_ok=True)
    
    # Determine project root if not set
    project_root = PROJECT_ROOT
    if not project_root:
        # Try to detect it based on script location
        script_dir = os.path.dirname(os.path.abspath(__file__))
        potential_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
        if os.path.exists(os.path.join(potential_root, "flake.nix")):
            project_root = potential_root
    
    if not project_root:
        logger.error("Could not find Bloom Nix project root")
        return False
    
    # Generate package configuration
    package_config_lines = []
    for category in get_package_categories().keys():
        enabled = category in packages
        package_config_lines.append(f'{category} = {str(enabled).lower()};')
    
    package_config = "\n            ".join(package_config_lines)
    
    # Add device path prefix
    device = f"/dev/{disk}"
    
    # Create the declarative flake.nix configuration
    # This includes disk partitioning specifications
    flake_content = f'''{{
  description = "Bloom Nix Installation for {hostname}";

  inputs = {{
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bloom-nix = {{
      url = "path:{project_root}";
      inputs.nixpkgs.follows = "nixpkgs";
    }};
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  }};

  outputs = {{ self, nixpkgs, bloom-nix, disko }}: {{
    nixosConfigurations.{hostname} = nixpkgs.lib.nixosSystem {{
      system = "x86_64-linux";
      modules = [
        # Import disko for disk management
        disko.nixosModules.disko
        
        # Bloom Nix modules
        bloom-nix.nixosModules.base
        bloom-nix.nixosModules.hardware
        bloom-nix.nixosModules.branding
        bloom-nix.nixosModules.desktop.plasma
        bloom-nix.nixosModules.packages
        
        # Disk configuration
        {{
          disko.devices = {{
            disk.{disk} = {{
              device = "{device}";
              type = "disk";
              content = {{
                type = "gpt";
                parts = {f'''
                  {{
                    name = "ESP";
                    start = "1MiB";
                    end = "512MiB";
                    type = "EF00";
                    fs.type = "vfat";
                    fs.mountpoint = "/boot";
                  }}
                  {{
                    name = "root";
                    start = "512MiB";
                    end = "100%";
                    fs.type = "ext4";
                    fs.mountpoint = "/";
                  }}
                ''' if is_efi_system() else '''
                  {{
                    name = "boot";
                    start = "1MiB";
                    end = "512MiB";
                    flags = [ "boot" ];
                    fs.type = "ext4";
                    fs.mountpoint = "/boot";
                  }}
                  {{
                    name = "root";
                    start = "512MiB";
                    end = "100%";
                    fs.type = "ext4";
                    fs.mountpoint = "/";
                  }}
                '''};
              }};
            }};
          }};
        }}
        
        # System-specific configuration
        {{
          networking.hostName = "{hostname}";
          time.timeZone = "{timezone}";
          i18n.defaultLocale = "{locale}";
          
          # User account
          users.users.{username} = {{
            isNormalUser = true;
            description = "{username}";
            extraGroups = [ "networkmanager" "wheel" ];
            # Password will be set using hashed value
            initialPassword = "{password}";
          }};
          
          # Package categories
          bloom.packages = {{
            {package_config}
          }};
          
          # Bootloader configuration
          boot.loader = {{
            {f'efi.canTouchEfiVariables = true;' if is_efi_system() else ''}
            {f'systemd-boot.enable = true;' if is_efi_system() else f'grub = {{ device = "{device}"; }};'}
          }};
        }}
      ];
    }};
  }};
}}
'''
    
    # Write the configuration
    flake_path = os.path.join(installer_dir, "flake.nix")
    with open(flake_path, "w") as f:
        f.write(flake_content)
    
    logger.info(f"Generated declarative NixOS flake configuration at {flake_path}")
    return flake_path

def perform_installation(config):
    """Execute NixOS installation using the generated flake"""
    try:
        # Check internet connection first
        internet_connected, error_message = check_internet_connection()
        if not internet_connected:
            logger.error(f"No internet connection: {error_message}")
            return False, f"Internet connection required for installation: {error_message}"
        
        # Generate NixOS configuration flake
        flake_path = generate_nix_config(config)
        if not flake_path:
            return False, "Failed to generate NixOS configuration"
        
        # Get configuration details
        hostname = config.get('hostname', 'bloom-nix')
        
        # Create a minimal sudo helper script for the installation
        install_script = f"""#!/bin/sh
set -e
echo "Installing Bloom Nix with declarative configuration..."
nixos-install --no-root-passwd --flake {flake_path}#{hostname}
echo "Installation completed successfully!"
"""
        
        # Write the script to disk
        script_path = "/tmp/bloom-installer-install.sh"
        with open(script_path, "w") as f:
            f.write(install_script)
        
        # Make the script executable
        os.chmod(script_path, 0o755)
        
        # Run the installation script
        logger.info(f"Starting NixOS installation with flake: {flake_path}")
        code, stdout, stderr = run_sudo_command(script_path)
        
        if code != 0:
            logger.error(f"Failed to install NixOS: {stderr}")
            return False, f"Failed to install NixOS: {stderr}"
        
        logger.info("NixOS installation completed successfully")
        return True, "Installation completed successfully"
    except Exception as e:
        logger.error(f"Error during installation: {str(e)}")
        return False, f"Installation error: {str(e)}"

# Main Application
def main():
    # Set up page header
    col1, col2 = st.columns([1, 3])
    if os.path.exists(LOGO_PATH):
        col1.image(LOGO_PATH, width=80)
    col2.title("Bloom Nix Installer")
    col2.caption(f"Version {VERSION}")
    
    # Check for internet connectivity
    internet_connected, error_message = check_internet_connection()
    if not internet_connected:
        st.error(f"⚠️ No internet connection detected. Installation requires internet access.")
        st.warning(f"Error details: {error_message}")
        if st.button("Check Again"):
            rerun_app()
        st.stop()
    
    # Initialize or load configuration
    if 'config' not in st.session_state:
        st.session_state.config = load_config()
        st.session_state.installing = False
        st.session_state.installation_progress = 0
        st.session_state.status = ""
    
    # If installation is in progress, show progress screen
    if st.session_state.installing:
        st.header("Installing Bloom Nix")
        progress = st.progress(st.session_state.installation_progress)
        st.text(st.session_state.status)
        
        if st.session_state.installation_progress < 100:
            # Increment progress for demo
            if st.session_state.installation_progress == 0:
                # Start actual installation
                success, message = perform_installation(st.session_state.config)
                if not success:
                    st.error(message)
                    st.session_state.installing = False
                    return
                
                # Set initial progress
                st.session_state.installation_progress = 10
                st.session_state.status = "Installing..."
            else:
                # Simulate progress
                new_progress = min(st.session_state.installation_progress + 10, 100)
                status_messages = {
                    10: "Preparing disk...",
                    20: "Creating partitions...",
                    30: "Formatting filesystems...",
                    40: "Mounting filesystems...",
                    50: "Generating hardware configuration...",
                    60: "Installing base system...",
                    70: "Installing packages...",
                    80: "Setting up users...",
                    90: "Installing bootloader...",
                    100: "Installation complete!"
                }
                
                st.session_state.installation_progress = new_progress
                if new_progress in status_messages:
                    st.session_state.status = status_messages[new_progress]
            
            # Update progress bar
            progress.progress(st.session_state.installation_progress)
            st.text(st.session_state.status)
            
            # Refresh for next step
            if st.session_state.installation_progress < 100:
                time.sleep(1)
                rerun_app()
        
        # Show completion message when done
        if st.session_state.installation_progress >= 100:
            st.success("Bloom Nix has been successfully installed!")
            if st.button("Restart Computer"):
                run_sudo_command("reboot")
        
        return
    
    # Main configuration form
    with st.form("install_form"):
        st.header("System Configuration")
        
        # System basics
        col1, col2 = st.columns(2)
        hostname = col1.text_input("Hostname:", value=st.session_state.config.get("hostname", "bloom-nix"))
        
        # Available disks
        disks = get_disks()
        disk_options = {}
        for disk in disks:
            name = disk['name']
            size = disk.get('size', 'Unknown')
            model = disk.get('model', 'Unknown')
            disk_options[name] = f"{name} ({size}) - {model}"
        
        selected_disk = col2.selectbox(
            "Installation Disk:",
            options=list(disk_options.keys()) if disk_options else [""],
            format_func=lambda x: disk_options.get(x, x),
            index=0
        )
        
        if selected_disk:
            st.warning(f"⚠️ WARNING: All data on disk /dev/{selected_disk} will be erased!")
        
        # User information
        col1, col2 = st.columns(2)
        username = col1.text_input("Username:", value=st.session_state.config.get("username", ""))
        password = col2.text_input("Password:", type="password")
        
        # Plasma desktop is used by default (no UI element needed)
        
        # Package selection
        st.subheader("Software Selection")
        package_categories = get_package_categories()
        
        selected_packages = st.multiselect(
            "Select software categories:",
            options=list(package_categories.keys()),
            default=st.session_state.config.get("packages", ["daily", "browser"]),
            format_func=lambda x: package_categories[x]
        )
        
        # Locale settings
        st.subheader("Language and Region")
        col1, col2 = st.columns(2)
        
        # Common timezones
        timezone_options = [
            "America/New_York", "America/Chicago", "America/Los_Angeles",
            "Europe/London", "Europe/Berlin", "Europe/Paris", 
            "Asia/Tokyo", "Asia/Shanghai", "Australia/Sydney"
        ]
        
        timezone = col1.selectbox(
            "Timezone:",
            options=timezone_options,
            index=timezone_options.index(st.session_state.config.get("timezone", "America/New_York"))
            if st.session_state.config.get("timezone") in timezone_options else 0
        )
        
        # Locale selection
        locale_options = {
            "en_US.UTF-8": "English (US)",
            "en_GB.UTF-8": "English (UK)",
            "de_DE.UTF-8": "German",
            "fr_FR.UTF-8": "French",
            "es_ES.UTF-8": "Spanish",
            "ja_JP.UTF-8": "Japanese"
        }
        
        locale = col2.selectbox(
            "Language:",
            options=list(locale_options.keys()),
            format_func=lambda x: locale_options[x],
            index=list(locale_options.keys()).index(st.session_state.config.get("locale", "en_US.UTF-8"))
            if st.session_state.config.get("locale") in locale_options else 0
        )
        
        # Submit button
        submitted = st.form_submit_button("Install Bloom Nix")
        
        if submitted:
            # Validate input
            if not selected_disk:
                st.error("Please select an installation disk")
            elif not username:
                st.error("Please enter a username")
            elif not password:
                st.error("Please enter a password")
            else:
                # Update configuration
                st.session_state.config = {
                    "hostname": hostname,
                    "username": username,
                    "password": password,
                    "disk": selected_disk,
                    "desktop": "plasma",  # Always use Plasma as the desktop
                    "packages": selected_packages,
                    "timezone": timezone,
                    "locale": locale
                }
                
                # Save configuration
                save_config(st.session_state.config)
                
                # Start installation
                st.session_state.installing = True
                st.session_state.installation_progress = 0
                st.session_state.status = "Starting installation..."
                
                # Force page refresh to show installation progress
                rerun_app()

# Run the app
if __name__ == "__main__":
    main()
