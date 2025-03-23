#!/usr/bin/env python3
"""
Bloom Nix Installer
A modern, web-based installer using Streamlit for the Bloom Nix distribution
"""

import streamlit as st
import os
import sys
import json
import time
import subprocess
import platform
import re
from pathlib import Path
import tempfile
import logging
from typing import List, Dict, Any, Tuple, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/tmp/bloom-nix-installer.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("bloom-installer")

# Constants
INSTALLER_VERSION = "1.0.0"
INSTALLER_CONFIG = "/tmp/bloom-nix-installer.json"
INSTALLER_RUNNING_MARKER = "/tmp/bloom-installer-running"
SUDO_HELPER_SCRIPT = "/etc/bloom-installer/sudo-helper.py"

# Create a marker file to indicate the installer is running
Path(INSTALLER_RUNNING_MARKER).touch()

# Define theme colors
THEME_PRIMARY = "#FF5733"  # Orange/red
THEME_SECONDARY = "#000d33"  # Dark blue
THEME_BG = "#1E1E1E"  # Dark background
THEME_TEXT = "#FFFFFF"  # White text

# Custom CSS to style the app
st.markdown("""
<style>
    .main {
        background-color: #1E1E1E;
        color: #FFFFFF;
    }
    .stButton button {
        background-color: #FF5733;
        color: white;
        font-weight: bold;
        border-radius: 4px;
        padding: 0.5rem 1rem;
        border: none;
    }
    .stButton button:hover {
        background-color: #FF7052;
    }
    .stProgress .st-bo {
        background-color: #000d33;
    }
    .stProgress .st-bp {
        background-color: #FF5733;
    }
    .css-145kmo2 {
        border: 2px solid #FF5733;
        border-radius: 4px;
    }
    .css-18e3th9 {
        padding-top: 2rem;
    }
    h1, h2, h3 {
        color: #FF5733;
    }
    .stTextInput input, .stSelectbox select {
        background-color: #2A2A2A;
        color: white;
        border: 1px solid #444444;
    }
    .stCheckbox label {
        color: white;
    }
    .css-1adrfps {
        background-color: #2A2A2A;
    }
</style>
""", unsafe_allow_html=True)

# Helper functions for system operations
def run_sudo_command(command: str, description: str = None) -> Tuple[int, str, str]:
    """
    Run a command with sudo privileges using the helper script
    Returns: (return_code, stdout, stderr)
    """
    logger.info(f"Running sudo command: {command}")
    
    if description:
        st.text(f"⏳ {description}...")
    
    try:
        result = subprocess.run(
            ["sudo", "python3", SUDO_HELPER_SCRIPT, command],
            capture_output=True,
            text=True
        )
        logger.info(f"Command completed with return code: {result.returncode}")
        if result.stdout:
            logger.info(f"Command stdout: {result.stdout}")
        if result.stderr:
            logger.warning(f"Command stderr: {result.stderr}")
        
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        logger.error(f"Error running command: {str(e)}")
        return 1, "", str(e)

def get_available_disks() -> List[Dict[str, str]]:
    """Get list of available disks for installation"""
    logger.info("Getting available disks")
    
    try:
        # Ask our sudo helper to get disk information
        code, stdout, stderr = run_sudo_command("list_disks")
        
        if code != 0:
            logger.error(f"Error getting disks: {stderr}")
            return []
        
        disks = json.loads(stdout)
        logger.info(f"Found {len(disks)} disks")
        return disks
    except Exception as e:
        logger.error(f"Error parsing disk information: {str(e)}")
        return []

def is_efi_system() -> bool:
    """Check if system is booted in UEFI mode"""
    return os.path.exists("/sys/firmware/efi")

def save_config(config: Dict[str, Any]) -> None:
    """Save configuration to a file"""
    logger.info(f"Saving configuration to {INSTALLER_CONFIG}")
    with open(INSTALLER_CONFIG, 'w') as f:
        json.dump(config, f, indent=2)

def load_config() -> Dict[str, Any]:
    """Load configuration from a file"""
    if os.path.exists(INSTALLER_CONFIG):
        logger.info(f"Loading configuration from {INSTALLER_CONFIG}")
        try:
            with open(INSTALLER_CONFIG, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading configuration: {str(e)}")
    
    logger.info("No configuration found, using defaults")
    return {
        "hostname": "bloom-nix",
        "username": "",
        "fullname": "",
        "timezone": "America/New_York",
        "locale": "en_US.UTF-8",
        "keyboard": "us",
        "selected_packages": ["daily", "browser", "utils"],
        "disk": "",
        "partition_method": "auto",
        "use_project_structure": True,
    }

def get_project_structure_info() -> Dict[str, str]:
    """Get information about the Bloom Nix project structure"""
    info = {}
    for var in ["BLOOM_PROJECT_ROOT", "BLOOM_MODULE_BASE", "BLOOM_MODULE_DESKTOP", 
                "BLOOM_MODULE_HARDWARE", "BLOOM_MODULE_PACKAGES", "BLOOM_MODULE_BRANDING", 
                "BLOOM_HOST_CONFIG", "BLOOM_ENABLE_PLASMA6"]:
        info[var] = os.environ.get(var, "")
    
    return info

def has_project_structure() -> bool:
    """Check if the Bloom Nix project structure is available"""
    return bool(os.environ.get("BLOOM_PROJECT_ROOT", ""))

# Main application
def main():
    # Initialize session state for multi-page functionality
    if 'page' not in st.session_state:
        st.session_state.page = 'welcome'
        st.session_state.config = load_config()
        st.session_state.installation_complete = False
        st.session_state.installation_log = []
        st.session_state.installation_progress = 0
        st.session_state.installation_status = ""
        st.session_state.project_structure = get_project_structure_info()
        st.session_state.has_project = has_project_structure()
    
    # Title with logo (if available)
    col1, col2 = st.columns([1, 3])
    logo_path = "/etc/bloom-installer/logo.png"
    if os.path.exists(logo_path):
        col1.image(logo_path, width=100)
    
    col2.title(f"Bloom Nix Installer")
    col2.caption(f"Version {INSTALLER_VERSION}")
    
    # Render the current page
    if st.session_state.page == 'welcome':
        show_welcome_page()
    elif st.session_state.page == 'disk_selection':
        show_disk_selection_page()
    elif st.session_state.page == 'user_setup':
        show_user_setup_page()
    elif st.session_state.page == 'package_selection':
        show_package_selection_page()
    elif st.session_state.page == 'locale_setup':
        show_locale_setup_page()
    elif st.session_state.page == 'summary':
        show_summary_page()
    elif st.session_state.page == 'installation':
        show_installation_page()
    elif st.session_state.page == 'complete':
        show_completion_page()

def show_welcome_page():
    st.markdown("""
    ## Welcome to Bloom Nix!
    
    This installer will guide you through the process of installing Bloom Nix on your computer.
    
    Before proceeding, please make sure:
    
    - You have backed up any important data
    - Your computer is connected to power
    - You have at least 20GB of free disk space
    
    Bloom Nix features:
    - Beautiful KDE Plasma 6 desktop environment
    - Rolling-release model with easy system upgrades
    - Declarative system configuration
    """)
    
    # Show system information
    memory_gb = round(os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') / (1024.**3), 1)
    cpu_info = "Unknown"
    try:
        with open('/proc/cpuinfo') as f:
            for line in f:
                if line.startswith('model name'):
                    cpu_info = line.split(':', 1)[1].strip()
                    break
    except:
        pass
    
    st.info(f"""
    **System Information**:
    - CPU: {cpu_info}
    - Memory: {memory_gb} GB RAM
    - Boot Mode: {'UEFI' if is_efi_system() else 'BIOS/Legacy'}
    - Project Structure: {'Available' if st.session_state.has_project else 'Not Detected'}
    """)
    
    if st.button("Continue", use_container_width=True):
        st.session_state.page = 'disk_selection'

def show_disk_selection_page():
    st.header("Disk Selection")
    st.markdown("Select the disk where you want to install Bloom Nix.")
    
    # Get available disks
    disks = get_available_disks()
    
    if not disks:
        st.error("No disks found. Please make sure you have at least one disk available.")
        if st.button("Retry", use_container_width=True):
            st.experimental_rerun()
        return
    
    # Create disk options for the selectbox
    disk_options = {}
    for disk in disks:
        # Format as "sda (500GB) - Samsung SSD"
        name = disk['name']
        size = disk['size']
        model = disk.get('model', 'Unknown')
        disk_options[name] = f"{name} ({size}) - {model}"
    
    # Select disk
    selected_disk = st.selectbox(
        "Select installation disk:",
        options=list(disk_options.keys()),
        format_func=lambda x: disk_options[x]
    )
    
    st.warning(f"⚠️ WARNING: All data on disk /dev/{selected_disk} will be erased!")
    
    # Partitioning method
    partition_method = st.radio(
        "Partitioning method:",
        options=["auto", "manual"],
        format_func=lambda x: "Automatic partitioning (recommended)" if x == "auto" else "Manual partitioning (advanced)",
        horizontal=True
    )
    
    # If manual partitioning selected, show information
    if partition_method == "manual":
        st.info("""
        With manual partitioning, you'll use a system tool to create your partitions.
        
        You'll need to create at least:
        - For UEFI systems: An EFI System Partition (500MB) and a root partition
        - For BIOS systems: A boot partition (1MB) and a root partition
        
        You may also want to create a swap partition.
        """)
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back", use_container_width=True):
        st.session_state.page = 'welcome'
    
    if col2.button("Continue", use_container_width=True):
        st.session_state.config["disk"] = selected_disk
        st.session_state.config["partition_method"] = partition_method
        save_config(st.session_state.config)
        
        if partition_method == "manual":
            # Launch manual partitioning tool (this would open in a separate window)
            run_sudo_command(f"launch_partitioning_tool /dev/{selected_disk}")
        
        st.session_state.page = 'user_setup'

def show_user_setup_page():
    st.header("User Account Setup")
    st.markdown("Create your user account for Bloom Nix.")
    
    # System hostname
    hostname = st.text_input("Computer name (hostname):", 
                             value=st.session_state.config.get("hostname", "bloom-nix"))
    
    # Username
    username = st.text_input("Username:", 
                             value=st.session_state.config.get("username", ""))
    if username and not re.match(r'^[a-z_][a-z0-9_-]*$', username):
        st.error("Username must start with a letter and contain only lowercase letters, numbers, underscores, and hyphens.")
    
    # Full name
    fullname = st.text_input("Full name:", 
                             value=st.session_state.config.get("fullname", ""))
    
    # Password
    password = st.text_input("Password:", type="password")
    confirm_password = st.text_input("Confirm password:", type="password")
    
    if password and confirm_password and password != confirm_password:
        st.error("Passwords do not match!")
    
    # Root account
    use_root = st.checkbox("Enable root account", 
                          value=st.session_state.config.get("use_root", False),
                          help="If enabled, you can set a separate root password. Otherwise, the root account will be disabled and your user will use sudo.")
    
    if use_root:
        root_password = st.text_input("Root password:", type="password")
        root_confirm = st.text_input("Confirm root password:", type="password")
        
        if root_password and root_confirm and root_password != root_confirm:
            st.error("Root passwords do not match!")
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back", use_container_width=True):
        st.session_state.page = 'disk_selection'
    
    continue_disabled = (
        not username or 
        not password or 
        password != confirm_password or
        not re.match(r'^[a-z_][a-z0-9_-]*$', username) or
        (use_root and (not root_password or root_password != root_confirm))
    )
    
    if col2.button("Continue", disabled=continue_disabled, use_container_width=True):
        # Save user information
        st.session_state.config["hostname"] = hostname
        st.session_state.config["username"] = username
        st.session_state.config["fullname"] = fullname
        st.session_state.config["password"] = password  # Will be hashed during installation
        st.session_state.config["use_root"] = use_root
        if use_root:
            st.session_state.config["root_password"] = root_password
        save_config(st.session_state.config)
        
        st.session_state.page = 'package_selection'

def show_package_selection_page():
    st.header("Software Selection")
    st.markdown("Select the software categories you want to install.")
    
    # Package categories with descriptions
    package_categories = {
        "gaming": "Gaming packages (Steam, Lutris, etc.)",
        "programming": "Development tools and languages",
        "multimedia": "Media creation and editing tools",
        "office": "Office and productivity tools",
        "daily": "Everyday applications",
        "browser": "Web browsers",
        "security": "Security and privacy tools",
        "networking": "Advanced networking tools",
        "virtualization": "Virtualization software",
        "utils": "System utilities and tools"
    }
    
    # Default selections
    if "selected_packages" not in st.session_state.config:
        st.session_state.config["selected_packages"] = ["daily", "browser", "utils"]
    
    selected_packages = st.multiselect(
        "Select software categories to install:",
        options=list(package_categories.keys()),
        default=st.session_state.config["selected_packages"],
        format_func=lambda x: f"{x} - {package_categories[x]}"
    )
    
    # Show details about selected packages
    if selected_packages:
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
        
        all_selected_pkgs = []
        for category in selected_packages:
            if category in package_details:
                all_selected_pkgs.extend(package_details[category])
        
        st.info(f"Selected packages: {', '.join(sorted(all_selected_pkgs))}")
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back", use_container_width=True):
        st.session_state.page = 'user_setup'
    
    if col2.button("Continue", use_container_width=True):
        st.session_state.config["selected_packages"] = selected_packages
        save_config(st.session_state.config)
        st.session_state.page = 'locale_setup'

def show_locale_setup_page():
    st.header("Language and Region Settings")
    st.markdown("Set your language, timezone, and keyboard layout.")
    
    # Timezone selection
    timezone_options = [
        "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
        "Europe/London", "Europe/Berlin", "Europe/Paris", "Europe/Rome", "Europe/Madrid",
        "Europe/Moscow", "Asia/Tokyo", "Asia/Shanghai", "Asia/Dubai", 
        "Australia/Sydney", "Pacific/Auckland"
    ]
    timezone = st.selectbox(
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
        "it_IT.UTF-8": "Italian",
        "ru_RU.UTF-8": "Russian",
        "zh_CN.UTF-8": "Chinese (Simplified)",
        "ja_JP.UTF-8": "Japanese",
        "ko_KR.UTF-8": "Korean"
    }
    locale = st.selectbox(
        "Language (Locale):",
        options=list(locale_options.keys()),
        format_func=lambda x: locale_options[x],
        index=list(locale_options.keys()).index(st.session_state.config.get("locale", "en_US.UTF-8"))
        if st.session_state.config.get("locale") in locale_options else 0
    )
    
    # Keyboard layout
    keyboard_options = {
        "us": "US English",
        "uk": "UK English",
        "de": "German",
        "fr": "French",
        "es": "Spanish",
        "it": "Italian",
        "ru": "Russian",
        "jp": "Japanese"
    }
    keyboard = st.selectbox(
        "Keyboard layout:",
        options=list(keyboard_options.keys()),
        format_func=lambda x: keyboard_options[x],
        index=list(keyboard_options.keys()).index(st.session_state.config.get("keyboard", "us"))
        if st.session_state.config.get("keyboard") in keyboard_options else 0
    )
    
    # Project structure option
    if st.session_state.has_project:
        use_project = st.checkbox(
            "Use Bloom Nix project structure",
            value=st.session_state.config.get("use_project_structure", True),
            help="Use the existing Bloom Nix configuration and module structure for installation"
        )
    else:
        use_project = False
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back", use_container_width=True):
        st.session_state.page = 'package_selection'
    
    if col2.button("Continue", use_container_width=True):
        st.session_state.config["timezone"] = timezone
        st.session_state.config["locale"] = locale
        st.session_state.config["keyboard"] = keyboard
        st.session_state.config["use_project_structure"] = use_project
        save_config(st.session_state.config)
        st.session_state.page = 'summary'

def show_summary_page():
    st.header("Installation Summary")
    st.markdown("Review your choices before installing Bloom Nix.")
    
    config = st.session_state.config
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("System")
        st.markdown(f"""
        **Disk**: /dev/{config['disk']}  
        **Partitioning**: {config['partition_method']}  
        **Hostname**: {config['hostname']}  
        **Boot mode**: {'UEFI' if is_efi_system() else 'BIOS/Legacy'}
        """)
        
        st.subheader("User")
        st.markdown(f"""
        **Username**: {config['username']}  
        **Full name**: {config['fullname']}  
        **Root account**: {'Enabled' if config.get('use_root', False) else 'Disabled'}
        """)
    
    with col2:
        st.subheader("Localization")
        st.markdown(f"""
        **Timezone**: {config['timezone']}  
        **Locale**: {config['locale']}  
        **Keyboard**: {config['keyboard']}
        """)
        
        st.subheader("Software")
        package_list = ", ".join(config.get('selected_packages', []))
        st.markdown(f"""
        **Desktop**: KDE Plasma 6  
        **Selected categories**: {package_list or "None"}  
        **Project structure**: {'Yes' if config.get('use_project_structure', False) else 'No'}
        """)
    
    st.warning("⚠️ WARNING: This will erase all data on the selected disk. Make sure you have backups of any important data.")
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back", use_container_width=True):
        st.session_state.page = 'locale_setup'
    
    if col2.button("Install Bloom Nix", use_container_width=True):
        st.session_state.page = 'installation'

def show_installation_page():
    st.header("Installing Bloom Nix")
    st.markdown("Please wait while Bloom Nix is being installed on your system.")
    
    # If installation hasn't started yet, start it
    if st.session_state.installation_progress == 0:
        st.session_state.installation_status = "Starting installation..."
        # Start installation in a background thread
        import threading
        threading.Thread(target=perform_installation).start()
    
    # Show progress bar
    progress_bar = st.progress(st.session_state.installation_progress)
    st.text(st.session_state.installation_status)
    
    # Display installation log
    with st.expander("Installation Log", expanded=False):
        log_text = "\n".join(st.session_state.installation_log)
        st.code(log_text)
    
    # Check if installation is complete
    if st.session_state.installation_complete:
        st.success("Installation completed successfully!")
        if st.button("Finish", use_container_width=True):
            st.session_state.page = 'complete'
    else:
        # Rerun to update the UI
        time.sleep(1)
        st.experimental_rerun()

def show_completion_page():
    st.header("Installation Complete")
    
    st.success("""
    ## Congratulations!
    
    Bloom Nix has been successfully installed on your system.
    
    You can now restart your computer to begin using your new Bloom Nix system.
    """)
    
    if st.button("Restart Now", use_container_width=True):
        # Run sudo command to reboot
        run_sudo_command("reboot")
    
    if st.button("Exit Installer", use_container_width=True):
        # Clean up and exit
        if os.path.exists(INSTALLER_RUNNING_MARKER):
            os.remove(INSTALLER_RUNNING_MARKER)
        sys.exit(0)

def perform_installation():
    """Perform the actual installation process"""
    try:
        config = st.session_state.config
        
        # Log the installation start
        log_message = f"Starting Bloom Nix installation on /dev/{config['disk']}"
        logger.info(log_message)
        st.session_state.installation_log.append(log_message)
        
        def update_progress(progress, status):
            """Update the installation progress and status"""
            st.session_state.installation_progress = progress
            st.session_state.installation_status = status
            log_message = f"Progress {progress}%: {status}"
            logger.info(log_message)
            st.session_state.installation_log.append(log_message)
        
        # Step 1: Prepare disk
        update_progress(5, "Preparing disk for installation...")
        
        if config['partition_method'] == 'auto':
            # Perform automatic partitioning
            disk = config['disk']
            is_uefi = is_efi_system()
            
            if is_uefi:
                # EFI partitioning
                cmd = f"auto_partition_uefi /dev/{disk}"
                code, stdout, stderr = run_sudo_command(cmd)
                if code != 0:
                    raise Exception(f"Failed to partition disk: {stderr}")
            else:
                # BIOS partitioning
                cmd = f"auto_partition_bios /dev/{disk}"
                code, stdout, stderr = run_sudo_command(cmd)
                if code != 0:
                    raise Exception(f"Failed to partition disk: {stderr}")
        else:
            # For manual partitioning, get the partition selection
            cmd = f"get_partition_info /dev/{config['disk']}"
            code, stdout, stderr = run_sudo_command(cmd)
            if code != 0:
                raise Exception(f"Failed to get partition information: {stderr}")
            
            partition_info = json.loads(stdout)
            st.session_state.installation_log.append(f"Partition information: {partition_info}")
            
            # Prompt user for partition selection in the UI
            # This would be handled separately since we're already at the installation page
        
        # Step 2: Mount filesystems
        update_progress(15, "Mounting filesystems...")
        
        cmd = f"mount_filesystems /dev/{config['disk']}"
        code, stdout, stderr = run_sudo_command(cmd)
        if code != 0:
            raise Exception(f"Failed to mount filesystems: {stderr}")
        
        # Step 3: Generate hardware configuration
        update_progress(25, "Generating hardware configuration...")
        
        cmd = "generate_hardware_config"
        code, stdout, stderr = run_sudo_command(cmd)
        if code != 0:
            raise Exception(f"Failed to generate hardware configuration: {stderr}")
        
        # Step 4: Copy project files if using project structure
        update_progress(35, "Setting up system configuration...")
        
        if config.get('use_project_structure', False) and st.session_state.has_project:
            cmd = "copy_project_files"
            code, stdout, stderr = run_sudo_command(cmd)
            if code != 0:
                raise Exception(f"Failed to copy project files: {stderr}")
        
        # Step 5: Create configuration.nix
        update_progress(45, "Creating system configuration...")
        
        # Create a temporary file with the configuration
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
            # Write the configuration to the file
            f.write(json.dumps(config))
            config_file = f.name
        
        cmd = f"create_system_config {config_file}"
        code, stdout, stderr = run_sudo_command(cmd)
        
        # Remove the temporary file
        os.unlink(config_file)
        
        if code != 0:
            raise Exception(f"Failed to create system configuration: {stderr}")
        
        # Step 6: Install NixOS
        update_progress(60, "Installing NixOS...")
        
        cmd = "install_nixos"
        code, stdout, stderr = run_sudo_command(cmd)
        if code != 0:
            raise Exception(f"Failed to install NixOS: {stderr}")
        
        # Step 7: Install bootloader
        update_progress(80, "Installing bootloader...")
        
        cmd = "install_bootloader"
        code, stdout, stderr = run_sudo_command(cmd)
        if code != 0:
            raise Exception(f"Failed to install bootloader: {stderr}")
        
        # Step 8: Finalize installation
        update_progress(90, "Finalizing installation...")
        
        cmd = "finalize_installation"
        code, stdout, stderr = run_sudo_command(cmd)
        if code != 0:
            raise Exception(f"Failed to finalize installation: {stderr}")
        
        # Installation complete
        update_progress(100, "Installation completed successfully!")
        st.session_state.installation_complete = True
        
    except Exception as e:
        # Log the error
        error_message = f"Installation failed: {str(e)}"
        logger.error(error_message)
        st.session_state.installation_log.append(error_message)
        st.session_state.installation_status = "Installation failed!"
        
        # Display error in the UI
        st.error(error_message)

if __name__ == "__main__":
    main()

