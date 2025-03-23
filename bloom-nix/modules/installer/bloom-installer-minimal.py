#!/usr/bin/env python3
"""
Bloom Nix Minimal Installer
A lightweight, web-based installer using Streamlit
"""

import streamlit as st
import os
import json
import subprocess
import time
import logging
from pathlib import Path

# Configure basic logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler("/tmp/bloom-nix-installer.log")]
)
logger = logging.getLogger("bloom-installer")

# Constants
INSTALLER_CONFIG = "/tmp/bloom-nix-installer.json"
INSTALLER_RUNNING_MARKER = "/tmp/bloom-installer-running"
VERSION = "1.0.0"

# Create a marker file to indicate the installer is running
Path(INSTALLER_RUNNING_MARKER).touch()

# Define theme colors
THEME_PRIMARY = "#FF5733"  # Orange/red
THEME_SECONDARY = "#000d33"  # Dark blue

# Custom CSS with minimal styling
st.markdown("""
<style>
    .main {
        background-color: #1E1E1E;
        color: #FFFFFF;
    }
    .stButton button {
        background-color: #FF5733;
        color: white;
        border-radius: 4px;
        border: none;
    }
    .stProgress .st-bp {
        background-color: #FF5733;
    }
    h1, h2, h3 {
        color: #FF5733;
    }
</style>
""", unsafe_allow_html=True)

# Helper functions
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
    return json.loads(stdout)

def is_efi_system():
    """Check if system is booted in UEFI mode"""
    return os.path.exists("/sys/firmware/efi")

def save_config(config):
    """Save configuration to file"""
    with open(INSTALLER_CONFIG, 'w') as f:
        json.dump(config, f)

def load_config():
    """Load configuration from file"""
    if os.path.exists(INSTALLER_CONFIG):
        try:
            with open(INSTALLER_CONFIG, 'r') as f:
                return json.load(f)
        except:
            pass
    return {"hostname": "bloom-nix", "selected_packages": ["daily", "browser"]}

def has_project_structure():
    """Check for project structure"""
    return bool(os.environ.get("BLOOM_PROJECT_ROOT", ""))

# Initialize session state
if 'page' not in st.session_state:
    st.session_state.page = 'welcome'
    st.session_state.config = load_config()
    st.session_state.installing = False
    st.session_state.installation_progress = 0
    st.session_state.status = ""
    st.session_state.has_project = has_project_structure()

# Display logo and title
col1, col2 = st.columns([1, 3])
logo_path = "/etc/bloom-installer/logo.png"
if os.path.exists(logo_path):
    col1.image(logo_path, width=80)

col2.title("Bloom Nix Installer")
col2.caption(f"Version {VERSION}")

# Main pages
def welcome_page():
    st.markdown("## Welcome to Bloom Nix!")
    st.markdown("""
    This installer will guide you through installing Bloom Nix on your computer.
    
    Before proceeding, please ensure:
    - You have backed up important data
    - Your computer is connected to power
    - You have at least 20GB of free disk space
    """)
    
    # System information in a simpler format
    memory_gb = round(os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') / (1024.**3), 1)
    st.info(f"Memory: {memory_gb} GB RAM | Boot Mode: {'UEFI' if is_efi_system() else 'BIOS'}")
    
    if st.button("Start Installation"):
        st.session_state.page = 'disk'

def disk_selection():
    st.header("Disk Selection")
    
    # Get available disks
    disks = get_disks()
    
    if not disks:
        st.error("No disks found.")
        if st.button("Retry"):
            st.experimental_rerun()
        return
    
    # Create disk options
    disk_options = {}
    for disk in disks:
        name = disk['name']
        size = disk.get('size', 'Unknown')
        model = disk.get('model', 'Unknown')
        disk_options[name] = f"{name} ({size}) - {model}"
    
    selected_disk = st.selectbox(
        "Select installation disk:",
        options=list(disk_options.keys()),
        format_func=lambda x: disk_options[x]
    )
    
    st.warning(f"⚠️ WARNING: All data on disk /dev/{selected_disk} will be erased!")
    
    partition_method = st.radio(
        "Partitioning method:",
        options=["auto", "manual"],
        format_func=lambda x: "Automatic" if x == "auto" else "Manual",
        horizontal=True
    )
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back"):
        st.session_state.page = 'welcome'
    
    if col2.button("Continue"):
        st.session_state.config["disk"] = selected_disk
        st.session_state.config["partition_method"] = partition_method
        save_config(st.session_state.config)
        
        if partition_method == "manual":
            run_sudo_command(f"launch_partitioning_tool /dev/{selected_disk}")
        
        st.session_state.page = 'user'

def user_setup():
    st.header("User Account Setup")
    
    # System hostname
    hostname = st.text_input("Hostname:", value=st.session_state.config.get("hostname", "bloom-nix"))
    
    # Username and password
    username = st.text_input("Username:", value=st.session_state.config.get("username", ""))
    password = st.text_input("Password:", type="password")
    confirm_password = st.text_input("Confirm password:", type="password")
    
    if password and confirm_password and password != confirm_password:
        st.error("Passwords do not match!")
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back"):
        st.session_state.page = 'disk'
    
    continue_disabled = not username or not password or password != confirm_password
    
    if col2.button("Continue", disabled=continue_disabled):
        st.session_state.config["hostname"] = hostname
        st.session_state.config["username"] = username
        st.session_state.config["password"] = password
        save_config(st.session_state.config)
        st.session_state.page = 'software'

def software_selection():
    st.header("Software Selection")
    
    # Package categories with simplified descriptions
    package_categories = {
        "gaming": "Gaming (Steam, Lutris)",
        "programming": "Development tools",
        "multimedia": "Media creation",
        "office": "Office applications",
        "daily": "Everyday apps",
        "browser": "Web browsers",
        "utils": "System utilities"
    }
    
    # Default selections
    if "selected_packages" not in st.session_state.config:
        st.session_state.config["selected_packages"] = ["daily", "browser"]
    
    selected_packages = st.multiselect(
        "Select software categories:",
        options=list(package_categories.keys()),
        default=st.session_state.config["selected_packages"],
        format_func=lambda x: package_categories[x]
    )
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back"):
        st.session_state.page = 'user'
    
    if col2.button("Continue"):
        st.session_state.config["selected_packages"] = selected_packages
        save_config(st.session_state.config)
        st.session_state.page = 'locale'

def locale_setup():
    st.header("Language and Region")
    
    # Simplified timezone selection
    timezone_options = [
        "America/New_York", "America/Chicago", "America/Los_Angeles",
        "Europe/London", "Europe/Berlin", "Europe/Paris", 
        "Asia/Tokyo", "Asia/Shanghai", "Australia/Sydney"
    ]
    timezone = st.selectbox(
        "Timezone:",
        options=timezone_options,
        index=0
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
    locale = st.selectbox(
        "Language:",
        options=list(locale_options.keys()),
        format_func=lambda x: locale_options[x]
    )
    
    # Project structure option
    if st.session_state.has_project:
        use_project = st.checkbox(
            "Use Bloom Nix project structure",
            value=True
        )
    else:
        use_project = False
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back"):
        st.session_state.page = 'software'
    
    if col2.button("Continue"):
        st.session_state.config["timezone"] = timezone
        st.session_state.config["locale"] = locale
        st.session_state.config["keyboard"] = "us"  # Default to US keyboard
        st.session_state.config["use_project_structure"] = use_project
        save_config(st.session_state.config)
        st.session_state.page = 'summary'

def show_summary():
    st.header("Installation Summary")
    
    config = st.session_state.config
    
    # Display a simplified summary
    st.markdown(f"""
    * **Disk**: /dev/{config['disk']} ({config['partition_method']} partitioning)
    * **System**: {config['hostname']} • {'UEFI' if is_efi_system() else 'BIOS'}
    * **User**: {config['username']}
    * **Software**: {', '.join(config.get('selected_packages', []))}
    * **Region**: {config.get('timezone', '')} • {config.get('locale', '')}
    """)
    
    st.warning("⚠️ All data on the selected disk will be erased!")
    
    col1, col2 = st.columns(2)
    
    if col1.button("Back"):
        st.session_state.page = 'locale'
    
    if col2.button("Install Bloom Nix"):
        st.session_state.page = 'install'
        st.session_state.installing = True
        st.session_state.installation_progress = 0
        st.session_state.status = "Starting installation..."

def perform_installation():
    if not st.session_state.installing:
        st.session_state.installing = True
        st.session_state.installation_progress = 0
        st.session_state.status = "Starting installation..."
    
    st.header("Installing Bloom Nix")
    
    # Show progress bar
    progress = st.progress(st.session_state.installation_progress)
    st.text(st.session_state.status)
    
    # If not done, continue installation steps
    if st.session_state.installation_progress < 100:
        # This would normally run in a separate thread
        # For simplicity, we'll simulate it with time.sleep
        
        config = st.session_state.config
        steps = [
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
        
        # Find the next step
        current_progress = st.session_state.installation_progress
        next_step = None
        
        for prog, msg in steps:
            if prog > current_progress:
                next_step = (prog, msg)
                break
        
        if next_step:
            # Update progress
            st.session_state.installation_progress = next_step[0]
            st.session_state.status = next_step[1]
            
            # In a real implementation, this would call the actual installation commands
            progress.progress(st.session_state.installation_progress)
            st.text(st.session_state.status)
            
            if st.session_state.installation_progress < 100:
                time.sleep(1)  # Simulate work being done
                st.experimental_rerun()
    
    # Show completion when done
    if st.session_state.installation_progress >= 100:
        st.success("Installation completed successfully!")
        
        if st.button("Restart Computer"):
            run_sudo_command("reboot")

# Route to the correct page
if st.session_state.page == 'welcome':
    welcome_page()
elif st.session_state.page == 'disk':
    disk_selection()
elif st.session_state.page == 'user':
    user_setup()
elif st.session_state.page == 'software':
    software_selection()
elif st.session_state.page == 'locale':
    locale_setup()
elif st.session_state.page == 'summary':
    show_summary()
elif st.session_state.page == 'install':
    perform_installation()
