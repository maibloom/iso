#!/usr/bin/env python3
"""
Bloom Nix Installer
A streamlined web-based installer for Bloom Nix
"""

import streamlit as st
import os
import json
import subprocess
import logging
import time
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
        result = subprocess.run(
            ["sudo", "python3", "/etc/bloom-installer/sudo-helper.py", command],
            capture_output=True,
            text=True
        )
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        logger.error(f"Error running command: {str(e)}")
        return 1, "", str(e)

def get_disks():
    """Get list of available disks"""
    code, stdout, stderr = run_sudo_command("list_disks")
    if code != 0:
        return []
    try:
        return json.loads(stdout)
    except:
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
        "partitioning": "auto",
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

# Function removed as we always use Plasma

def generate_nix_config(config):
    """Generate NixOS configuration from installer settings"""
    logger.info(f"Generating NixOS configuration with: {json.dumps(config)}")
    
    # Extract configuration values
    hostname = config.get('hostname', 'bloom-nix')
    username = config.get('username', 'user')
    timezone = config.get('timezone', 'America/New_York')
    locale = config.get('locale', 'en_US.UTF-8')
    disk = config.get('disk', '')
    # Always use Plasma as the desktop environment
    desktop = "plasma"
    packages = config.get('packages', [])
    
    # Create directory for the configuration
    os.makedirs("/mnt/etc/nixos", exist_ok=True)
    
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
    
    # Create flake.nix for installation
    flake_content = f'''{{
  description = "Bloom Nix Installation for {hostname}";

  inputs = {{
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bloom-nix.url = "path:{project_root}";
  }};

  outputs = {{ self, nixpkgs, bloom-nix }}: {{
    nixosConfigurations.{hostname} = nixpkgs.lib.nixosSystem {{
      system = "x86_64-linux";
      modules = [
        # Hardware configuration
        ./hardware-configuration.nix
        
        # Bloom Nix modules
        bloom-nix.nixosModules.base
        bloom-nix.nixosModules.hardware
        bloom-nix.nixosModules.branding
        {f'bloom-nix.nixosModules.desktop.{desktop}' if desktop != "none" else '# No desktop selected'}
        bloom-nix.nixosModules.packages
        
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
          }};
          
          # Boot loader configuration
          boot.loader = {{
            {f'efi.canTouchEfiVariables = true;' if is_efi_system() else ''}
            {f'systemd-boot.enable = true;' if is_efi_system() else f'grub = {{ device = "/dev/{disk}"; }};'}
          }};
          
          # Package categories
          bloom.packages = {{
            {package_config}
          }};
        }}
      ];
    }};
  }};
}}
'''
    
    # Write the configuration
    with open("/mnt/etc/nixos/flake.nix", "w") as f:
        f.write(flake_content)
    
    # Generate hardware configuration
    code, stdout, stderr = run_sudo_command(f"generate_hardware_config /mnt/etc/nixos {disk}")
    if code != 0:
        logger.error(f"Failed to generate hardware configuration: {stderr}")
        return False
    
    return True

def perform_installation(config):
    """Execute the installation process"""
    steps = [
        (0, "Starting installation..."),
        (10, "Preparing disk..."),
        (20, "Creating partitions..."),
        (30, "Formatting filesystems..."),
        (40, "Mounting filesystems..."),
        (50, "Generating hardware configuration..."),
        (70, "Installing system..."),
        (80, "Setting up users..."),
        (90, "Installing bootloader..."),
        (100, "Installation complete!")
    ]
    
    # Get the disk and partitioning method
    disk = config.get('disk', '')
    partitioning = config.get('partitioning', 'auto')
    
    # Prepare the disk
    if partitioning == "auto":
        code, stdout, stderr = run_sudo_command(f"partition_disk {disk}")
        if code != 0:
            logger.error(f"Failed to partition disk: {stderr}")
            return False, "Failed to partition disk"
    
    # Create NixOS configuration
    if not generate_nix_config(config):
        return False, "Failed to generate NixOS configuration"
    
    # Install the system
    code, stdout, stderr = run_sudo_command("install_system")
    if code != 0:
        logger.error(f"Failed to install system: {stderr}")
        return False, "Failed to install system"
    
    # Set the user password
    username = config.get('username', '')
    password = config.get('password', '')
    if username and password:
        code, stdout, stderr = run_sudo_command(f"set_password {username} {password}")
        if code != 0:
            logger.error(f"Failed to set password: {stderr}")
            # Not a critical error, continue
    
    return True, "Installation completed successfully"

# Main Application
def main():
    # Set up page header
    col1, col2 = st.columns([1, 3])
    if os.path.exists(LOGO_PATH):
        col1.image(LOGO_PATH, width=80)
    col2.title("Bloom Nix Installer")
    col2.caption(f"Version {VERSION}")
    
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
                st.experimental_rerun()
        
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
                    "partitioning": "auto",  # For simplicity, always use auto partitioning
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
                st.experimental_rerun()

# Run the app
if __name__ == "__main__":
    main()
