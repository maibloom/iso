#!/bin/bash

# Bloom NixOS Installer Script
# A simple, reliable installer for Bloom NixOS

# Text formatting
BOLD="\e[1m"
RESET="\e[0m"
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"

# Function to display section headers
section() {
    echo -e "\n${BOLD}${BLUE}==>${RESET} ${BOLD}$1${RESET}"
}

# Function to display success messages
success() {
    echo -e "${GREEN}✓${RESET} $1"
}

# Function to display error messages
error() {
    echo -e "${RED}✗${RESET} $1"
}

# Function to display warning messages
warning() {
    echo -e "${YELLOW}!${RESET} $1"
}

# Function to prompt for confirmation
confirm() {
    while true; do
        read -p "$1 [y/N] " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* | "" ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Function to display disks
show_disks() {
    section "Available Disks"
    lsblk -d -p -n -o NAME,SIZE,MODEL | grep -v loop
    echo ""
}

# Function to partition and format a disk
partition_disk() {
    local disk=$1
    
    section "Partitioning Disk: $disk"
    
    # Create GPT partition table
    echo "Creating partition table..."
    parted --script "$disk" -- mklabel gpt
    
    # Create EFI system partition (512MiB)
    echo "Creating EFI system partition..."
    parted --script "$disk" -- mkpart ESP fat32 1MiB 512MiB
    parted --script "$disk" -- set 1 boot on
    
    # Create swap partition (8GiB)
    echo "Creating swap partition..."
    parted --script "$disk" -- mkpart swap linux-swap 512MiB 8.5GiB
    
    # Create root partition (rest of disk)
    echo "Creating root partition..."
    parted --script "$disk" -- mkpart primary 8.5GiB 100%
    
    # Find partitions
    local efi_part="${disk}1"
    local swap_part="${disk}2"
    local root_part="${disk}3"
    
    if [[ "$disk" == *"nvme"* ]]; then
        efi_part="${disk}p1"
        swap_part="${disk}p2"
        root_part="${disk}p3"
    fi
    
    # Format partitions
    echo "Formatting EFI partition..."
    mkfs.fat -F 32 "$efi_part"
    
    echo "Formatting swap partition..."
    mkswap "$swap_part"
    
    echo "Formatting root partition..."
    mkfs.ext4 "$root_part"
    
    # Mount partitions
    echo "Mounting partitions..."
    mount "$root_part" /mnt
    mkdir -p /mnt/boot
    mount "$efi_part" /mnt/boot
    swapon "$swap_part"
    
    success "Disk partitioning complete"
}

# Function to generate hardware configuration
generate_hw_config() {
    section "Generating Hardware Configuration"
    nixos-generate-config --root /mnt
    success "Hardware configuration generated"
}

# Function to copy Bloom modules to target system
copy_modules() {
    section "Copying Bloom NixOS Modules"
    mkdir -p /mnt/etc/nixos/bloom-modules
    cp -r /etc/nixos/modules/* /mnt/etc/nixos/bloom-modules/
    success "Modules copied to target system"
}

# Function to generate the full NixOS configuration
generate_config() {
    local hostname=$1
    local username=$2
    local password=$3
    
    section "Generating NixOS Configuration"
    
    cat > /mnt/etc/nixos/configuration.nix << EOF
# Bloom NixOS Configuration
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./bloom-modules/base.nix
    ./bloom-modules/hardware-base.nix
    ./bloom-modules/plasma.nix
    ./bloom-modules/branding.nix
  ];
  
  # Network configuration
  networking.hostName = "$hostname";
  
  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # User configuration
  users.users.$username = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "$password";
  };
  
  # Desktop environment
  services.desktopManager.plasma6.enable = true;
  services.displayManager = {
    sddm.enable = true;
    defaultSession = "plasma";
  };
  
  # Fix renamed options
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
    };
  };
  
  # New path for OpenGL configuration
  hardware.graphics.enable = true;
  
  # Basic services
  services.printing.enable = true;
  services.openssh.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  
  # Common packages
  environment.systemPackages = with pkgs; [
    firefox
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.plasma-systemmonitor
    git
    wget
    curl
  ];
  
  # Distribution branding
  system.nixos.distroName = "Bloom NixOS";
  system.nixos.distroId = "bloom";
}
EOF
    
    success "Configuration file generated"
}

# Function to install NixOS
install_nixos() {
    section "Installing Bloom NixOS"
    
    echo "This may take a while depending on your internet connection and hardware..."
    echo "Installation logs will be displayed below:"
    echo ""
    
    nixos-install --no-root-passwd
    
    if [ $? -eq 0 ]; then
        success "Installation completed successfully!"
        echo ""
        echo "You can now reboot into your new Bloom NixOS system."
        echo "Run 'reboot' to restart your computer."
    else
        error "Installation failed. Check the logs above for errors."
        echo ""
        echo "You can try to fix any issues and run 'nixos-install' manually,"
        echo "or restart this installer script."
    fi
}

# Main installation process
main() {
    # Display welcome message
    clear
    echo -e "${BOLD}${BLUE}"
    echo "========================================"
    echo "         Bloom NixOS Installer         "
    echo "========================================"
    echo -e "${RESET}"
    echo "This script will guide you through installing Bloom NixOS on your system."
    echo "Make sure you have backed up any important data before proceeding."
    echo ""
    
    # Display available disks
    show_disks
    
    # Prompt for disk selection
    read -p "Enter the full path of the disk to install to (e.g., /dev/sda): " target_disk
    
    # Confirm disk selection
    if ! confirm "WARNING: All data on $target_disk will be erased. Continue?"; then
        echo "Installation aborted."
        exit 1
    fi
    
    # Collect system configuration
    echo ""
    read -p "Enter a hostname for your computer [bloom-nixos]: " hostname
    hostname=${hostname:-bloom-nixos}
    
    read -p "Enter a username for your account: " username
    while [ -z "$username" ]; do
        echo "Username cannot be empty"
        read -p "Enter a username for your account: " username
    done
    
    read -s -p "Enter a password for your account: " password
    echo ""
    read -s -p "Confirm password: " password_confirm
    echo ""
    
    while [ "$password" != "$password_confirm" ]; do
        echo "Passwords do not match"
        read -s -p "Enter a password for your account: " password
        echo ""
        read -s -p "Confirm password: " password_confirm
        echo ""
    done
    
    # Confirm installation
    echo ""
    section "Installation Summary"
    echo "Target disk: $target_disk"
    echo "Hostname: $hostname"
    echo "Username: $username"
    echo ""
    
    if ! confirm "Ready to begin installation. Continue?"; then
        echo "Installation aborted."
        exit 1
    fi
    
    # Begin installation
    partition_disk "$target_disk"
    generate_hw_config
    copy_modules
    generate_config "$hostname" "$username" "$password"
    install_nixos
}

# Run the main function
main
