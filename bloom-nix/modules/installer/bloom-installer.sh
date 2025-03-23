#!/usr/bin/env bash
#===============================================================================
# Bloom Nix Installer
# A beautiful TUI installer for Bloom Nix
# License: MIT
#===============================================================================

# Set strict error handling
set -e

# Colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Installer configuration
DISTRO_NAME="Bloom Nix"
DISTRO_VERSION="1.0"
DIALOG_TITLE="$DISTRO_NAME Installer"
LOG_FILE="/tmp/bloom-nix-installer.log"
INSTALLER_CONFIG="/tmp/bloom-nix-install.conf"
SELECTED_PACKAGES_FILE="/tmp/bloom-nix-packages.list"
SPINNER="/-\|"  # For spinning animation during installation

# Dialog options for a nicer display
DIALOG_OPTS="--colors --begin 2 2 --no-collapse --no-shadow"
export DIALOGRC="/tmp/dialogrc"

# Enable mouse support and set nice colors for dialog
cat > "$DIALOGRC" << EOF
# Dialog configuration file with nice colors
screen_color = (CYAN,BLACK,ON)
title_color = (BLACK,CYAN,ON)
dialog_color = (BLACK,WHITE,OFF)
button_active_color = (WHITE,BLUE,ON)
button_inactive_color = (BLACK,WHITE,OFF)
button_key_active_color = (WHITE,BLUE,ON)
button_key_inactive_color = (RED,WHITE,OFF)
button_label_active_color = (WHITE,BLUE,ON)
button_label_inactive_color = (BLACK,WHITE,OFF)
inputbox_color = (BLACK,WHITE,OFF)
inputbox_border_color = (BLACK,WHITE,OFF)
searchbox_color = (BLACK,WHITE,OFF)
searchbox_title_color = (BLACK,CYAN,ON)
searchbox_border_color = (BLACK,WHITE,OFF)
position_indicator_color = (WHITE,BLUE,ON)
menubox_color = (BLACK,WHITE,OFF)
menubox_border_color = (BLACK,WHITE,OFF)
item_color = (BLACK,WHITE,OFF)
item_selected_color = (WHITE,BLUE,ON)
tag_color = (BLACK,CYAN,ON)
tag_selected_color = (WHITE,BLUE,ON)
tag_key_color = (RED,WHITE,OFF)
tag_key_selected_color = (RED,BLUE,ON)
check_color = (BLACK,WHITE,OFF)
check_selected_color = (WHITE,BLUE,ON)
uarrow_color = (RED,WHITE,OFF)
darrow_color = (RED,WHITE,OFF)
itemhelp_color = (BLACK,CYAN,ON)
form_active_text_color = (WHITE,BLUE,ON)
form_text_color = (BLACK,CYAN,ON)
form_item_readonly_color = (CYAN,WHITE,ON)
use_shadow = OFF
use_colors = ON
EOF

# Enable extended globbing
shopt -s extglob

# Check for project structure environment variables
if [ -n "$BLOOM_PROJECT_ROOT" ]; then
    # Log project structure information
    echo "Bloom Nix Project Structure Detected" >> "$LOG_FILE"
    echo "Project Root: $BLOOM_PROJECT_ROOT" >> "$LOG_FILE"
    echo "Base Module: $BLOOM_MODULE_BASE" >> "$LOG_FILE"
    echo "Desktop Module: $BLOOM_MODULE_DESKTOP" >> "$LOG_FILE"
    echo "Hardware Module: $BLOOM_MODULE_HARDWARE" >> "$LOG_FILE"
    echo "Packages Module: $BLOOM_MODULE_PACKAGES" >> "$LOG_FILE"
    echo "Branding Module: $BLOOM_MODULE_BRANDING" >> "$LOG_FILE"
    echo "Host Config: $BLOOM_HOST_CONFIG" >> "$LOG_FILE"
    echo "Enable Plasma 6: $BLOOM_ENABLE_PLASMA6" >> "$LOG_FILE"
    
    # Store project structure information in config
    echo "BLOOM_PROJECT_ROOT=\"$BLOOM_PROJECT_ROOT\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_MODULE_BASE=\"$BLOOM_MODULE_BASE\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_MODULE_DESKTOP=\"$BLOOM_MODULE_DESKTOP\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_MODULE_HARDWARE=\"$BLOOM_MODULE_HARDWARE\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_MODULE_PACKAGES=\"$BLOOM_MODULE_PACKAGES\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_MODULE_BRANDING=\"$BLOOM_MODULE_BRANDING\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_HOST_CONFIG=\"$BLOOM_HOST_CONFIG\"" >> "$INSTALLER_CONFIG"
    echo "BLOOM_ENABLE_PLASMA6=\"$BLOOM_ENABLE_PLASMA6\"" >> "$INSTALLER_CONFIG"
fi

# Ensure dialog is available through the Nix environment
if ! type dialog >/dev/null 2>&1; then
    echo -e "${RED}Error: dialog is not installed in this Nix environment.${NC}"
    echo "Please add the required dependencies to your system configuration."
    exit 1
fi

# Clean install environment
rm -f "$LOG_FILE" "$INSTALLER_CONFIG" "$SELECTED_PACKAGES_FILE"
touch "$LOG_FILE" "$INSTALLER_CONFIG" "$SELECTED_PACKAGES_FILE"

#===============================================================================
# Helper Functions
#===============================================================================

# Simple logging function
log() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Print a pretty header
print_header() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    echo "  ____  _                            _   _ _         "
    echo " | __ )| | ___   ___  _ __ ___      | \\ | (_)_  __  "
    echo " |  _ \\| |/ _ \\ / _ \\| '_ \` _ \\ ____|  \\| | \\ \\/ /  "
    echo " | |_) | | (_) | (_) | | | | | |____| |\\  | |>  <   "
    echo " |____/|_|\\___/ \\___/|_| |_| |_|    |_| \\_|_/_/\\_\\  "
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD} $DISTRO_NAME Installer - Version $DISTRO_VERSION ${NC}\n"
}

# Show progress spinner while running a command
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr=$SPINNER
    while [ "$(ps a | awk '{print $1}' | grep "$pid")" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Execute a command with a spinner, and log output
execute() {
    local cmd="$1"
    local msg="$2"
    echo -e "${YELLOW}$msg...${NC}"
    log "Executing: $cmd"
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    show_spinner $!
    wait $!
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "${RED}✖ Failed: $msg${NC}"
        log "Command failed with status $status"
        exit 1
    else
        echo -e "${GREEN}✓ Done: $msg${NC}"
    fi
    return $status
}

# Display error message and exit
error_exit() {
    echo -e "${RED}${BOLD}ERROR: $1${NC}" 1>&2
    log "ERROR: $1"
    exit 1
}

# Press any key to continue
press_any_key() {
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Function to copy project files to the target system
copy_project_files() {
    local target_dir="$1"
    
    if [ -n "$BLOOM_PROJECT_ROOT" ]; then
        log "Copying project files to $target_dir"
        
        # Use the project file copy script if available
        if [ -f "/etc/bloom-installer/copy-project-files.sh" ]; then
            execute "/etc/bloom-installer/copy-project-files.sh '$target_dir'" "Copying Bloom Nix project files"
        else
            # Fallback manual copy
            mkdir -p "$target_dir/modules"
            mkdir -p "$target_dir/hosts/desktop"
            
            # Copy module directories if they exist
            for module in base desktop hardware packages branding; do
                var_name="BLOOM_MODULE_${module^^}"
                module_path="${!var_name}"
                
                if [ -n "$module_path" ] && [ -d "$module_path" ]; then
                    execute "cp -r '$module_path' '$target_dir/modules/$module'" "Copying $module module"
                fi
            done
            
            # Copy host configuration
            if [ -n "$BLOOM_HOST_CONFIG" ] && [ -d "$BLOOM_HOST_CONFIG" ]; then
                execute "cp -r '$BLOOM_HOST_CONFIG/'* '$target_dir/hosts/desktop/'" "Copying host configuration"
            fi
        fi
        
        log "Project files copied successfully"
        return 0
    else
        log "No project structure detected, skipping copy"
        return 1
    fi
}

#===============================================================================
# Core Installation Functions
#===============================================================================

welcome_screen() {
    print_header
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Welcome to $DISTRO_NAME\Zn" \
           --msgbox "\n\Z3Welcome to the $DISTRO_NAME Installer!\Zn\n\nThis installer will guide you through setting up $DISTRO_NAME on your computer. Before proceeding, please make sure you:\n\n- Have backed up important data\n- Are connected to the internet (if needed)\n- Have at least 20GB of free disk space\n\nSelect OK to continue." \
           15 60
    
    # Confirm installation
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Confirm Installation\Zn" \
           --yesno "\n\Z3Are you ready to install $DISTRO_NAME?\Zn\n\nThis may modify partitions on your disk and could result in data loss if not carefully configured." \
           10 60
    
    local choice=$?
    if [ $choice -ne 0 ]; then
        clear
        echo -e "${YELLOW}Installation cancelled by user. Exiting...${NC}"
        exit 0
    fi
}

check_system_requirements() {
    print_header
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check RAM
    local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$(awk "BEGIN {printf \"%.1f\", $total_mem / 1024 / 1024}")
    
    # Check disk space 
    local free_space=$(df -h | grep -w "/" | awk '{print $4}' | sed 's/G//')
    
    # Check if running in UEFI mode
    local is_uefi=0
    if [ -d "/sys/firmware/efi" ]; then
        is_uefi=1
    fi
    
    # Check CPU
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d':' -f2 | sed 's/^[ \t]*//')
    local cpu_cores=$(grep -c processor /proc/cpuinfo)
    
    # Display system information
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1System Information\Zn" \
           --msgbox "\n\Z3System Information:\Zn\n\n- CPU: $cpu_model ($cpu_cores cores)\n- Memory: ${mem_gb}GB RAM\n- Boot Mode: $([ $is_uefi -eq 1 ] && echo "UEFI" || echo "BIOS")\n- Available Space: ${free_space}GB\n\nYour system will be checked for compatibility issues during installation." \
           15 70
    
    # Save information to config
    echo "IS_UEFI=$is_uefi" >> "$INSTALLER_CONFIG"
    echo "SYSTEM_MEM=$mem_gb" >> "$INSTALLER_CONFIG"
    echo "CPU_CORES=$cpu_cores" >> "$INSTALLER_CONFIG"
}

select_disk() {
    print_header
    echo -e "${BLUE}Scanning available disks...${NC}"
    
    # Get list of disks
    local disks=()
    local descriptions=()
    
    # Use lsblk to get disk information
    while IFS= read -r line; do
        local disk=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $4}')
        local model=$(echo "$line" | cut -d' ' -f5- | sed 's/^[ \t]*//')
        disks+=("$disk")
        descriptions+=("$disk ($size) - $model")
    done < <(lsblk -d -o NAME,TYPE,SIZE,MODEL | grep "disk")
    
    # Create dialog options
    local options=()
    for i in "${!disks[@]}"; do
        options+=("${disks[$i]}" "${descriptions[$i]}")
    done
    
    # Show disk selection dialog
    local disk
    disk=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                 --title "\Z1Select Installation Disk\Zn" \
                 --menu "\n\Z3Select the disk where you want to install $DISTRO_NAME:\Zn" \
                 15 75 7 \
                 "${options[@]}" \
                 3>&1 1>&2 2>&3)
    
    # Save selected disk to config
    echo "INSTALL_DISK=$disk" >> "$INSTALLER_CONFIG"
    source "$INSTALLER_CONFIG"
    
    # Confirm disk selection
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Confirm Disk Selection\Zn" \
           --yesno "\n\Z3You have selected disk /dev/$INSTALL_DISK for installation.\Zn\n\n\Z1WARNING: All data on this disk will be erased!\Zn\n\nDo you want to continue?" \
           12 60
    
    local choice=$?
    if [ $choice -ne 0 ]; then
        select_disk
        return
    fi
    
    # Ask for partitioning method
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Partitioning Method\Zn" \
           --menu "\n\Z3How would you like to partition the disk?\Zn" \
           12 60 3 \
           "auto" "\Z2Automatic partitioning (recommended)\Zn" \
           "manual" "\Z2Manual partitioning (advanced)\Zn" \
           3>&1 1>&2 2>&3 > /tmp/partition_method
    
    PARTITION_METHOD=$(cat /tmp/partition_method)
    echo "PARTITION_METHOD=$PARTITION_METHOD" >> "$INSTALLER_CONFIG"
    
    if [ "$PARTITION_METHOD" = "manual" ]; then
        dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
               --title "\Z1Manual Partitioning\Zn" \
               --msgbox "\n\Z3You will now be directed to cfdisk to manually partition your disk.\Zn\n\nPlease create at least:\n- For UEFI: An EFI System Partition (500MB) and a root partition\n- For BIOS: A boot partition (1MB) and a root partition\n\nYou may also want to create a swap partition." \
               14 65
        
        # Launch cfdisk for manual partitioning
        cfdisk "/dev/$INSTALL_DISK"
        
        # After manual partitioning, let user identify partitions
        local partitions=()
        while IFS= read -r line; do
            local part=$(echo "$line" | awk '{print $1}' | sed 's/^\/dev\///')
            local size=$(echo "$line" | awk '{print $4}')
            local type=$(echo "$line" | awk '{print $6}')
            partitions+=("$part" "$size ($type)")
        done < <(lsblk -o NAME,TYPE,SIZE,FSTYPE "/dev/$INSTALL_DISK" | grep "part")
        
        # Root partition selection
        ROOT_PARTITION=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                        --title "\Z1Select Root Partition\Zn" \
                        --menu "\n\Z3Select the partition for root (/):\Zn" \
                        15 60 7 \
                        "${partitions[@]}" \
                        3>&1 1>&2 2>&3)
        
        echo "ROOT_PARTITION=$ROOT_PARTITION" >> "$INSTALLER_CONFIG"
        
        # Boot/EFI partition if needed
        if [ "$IS_UEFI" = "1" ]; then
            BOOT_PARTITION=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                            --title "\Z1Select EFI Partition\Zn" \
                            --menu "\n\Z3Select the EFI System Partition:\Zn" \
                            15 60 7 \
                            "${partitions[@]}" \
                            3>&1 1>&2 2>&3)
            
            echo "BOOT_PARTITION=$BOOT_PARTITION" >> "$INSTALLER_CONFIG"
        fi
        
        # Swap partition (optional)
        dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
               --title "\Z1Swap Partition\Zn" \
               --yesno "\n\Z3Do you want to use a swap partition?\Zn" \
               7 60
        
        if [ $? -eq 0 ]; then
            SWAP_PARTITION=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                            --title "\Z1Select Swap Partition\Zn" \
                            --menu "\n\Z3Select the swap partition:\Zn" \
                            15 60 7 \
                            "${partitions[@]}" \
                            3>&1 1>&2 2>&3)
            
            echo "SWAP_PARTITION=$SWAP_PARTITION" >> "$INSTALLER_CONFIG"
        fi
    fi
}

setup_user_accounts() {
    print_header
    echo -e "${BLUE}Setting up user accounts...${NC}"
    
    # Hostname
    local hostname
    hostname=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                    --title "\Z1Hostname\Zn" \
                    --inputbox "\n\Z3Enter a hostname for your computer:\Zn" \
                    8 50 "bloom-nix" \
                    3>&1 1>&2 2>&3)
    
    echo "HOSTNAME=$hostname" >> "$INSTALLER_CONFIG"
    
    # Username
    local username
    username=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                    --title "\Z1Create User\Zn" \
                    --inputbox "\n\Z3Enter your username:\Zn" \
                    8 50 \
                    3>&1 1>&2 2>&3)
    
    # Validate username
    while [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; do
        username=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                        --title "\Z1Create User\Zn" \
                        --inputbox "\n\Z1Invalid username. Username must start with a letter and contain only lowercase letters, numbers, underscores, and hyphens.\Zn\n\n\Z3Enter your username:\Zn" \
                        10 60 \
                        3>&1 1>&2 2>&3)
    done
    
    echo "USERNAME=$username" >> "$INSTALLER_CONFIG"
    
    # Full name
    local fullname
    fullname=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                    --title "\Z1Full Name\Zn" \
                    --inputbox "\n\Z3Enter your full name:\Zn" \
                    8 50 \
                    3>&1 1>&2 2>&3)
    
    echo "FULLNAME=$fullname" >> "$INSTALLER_CONFIG"
    
    # Password
    local password
    password=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                    --title "\Z1Set Password\Zn" \
                    --passwordbox "\n\Z3Enter your password:\Zn" \
                    8 50 \
                    3>&1 1>&2 2>&3)
    
    # Confirm password
    local password_confirm
    password_confirm=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                          --title "\Z1Confirm Password\Zn" \
                          --passwordbox "\n\Z3Confirm your password:\Zn" \
                          8 50 \
                          3>&1 1>&2 2>&3)
    
    # Validate passwords match
    while [ "$password" != "$password_confirm" ]; do
        dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
               --title "\Z1Password Error\Zn" \
               --msgbox "\n\Z1Passwords do not match. Please try again.\Zn" \
               7 50
        
        password=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                        --title "\Z1Set Password\Zn" \
                        --passwordbox "\n\Z3Enter your password:\Zn" \
                        8 50 \
                        3>&1 1>&2 2>&3)
        
        password_confirm=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                              --title "\Z1Confirm Password\Zn" \
                              --passwordbox "\n\Z3Confirm your password:\Zn" \
                              8 50 \
                              3>&1 1>&2 2>&3)
    done
    
    # Hash the password and store it securely (using mkpasswd from the Nix environment)
    local hashed_password=$(echo "$password" | mkpasswd -m sha-512 -s)
    echo "USER_PASSWORD=$hashed_password" >> "$INSTALLER_CONFIG"
    
    # Root password
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Root Password\Zn" \
           --yesno "\n\Z3Do you want to set a separate root password?\Zn\n\nIf not, the root account will be disabled and your user will use sudo." \
           9 60
    
    local use_root=$?
    echo "USE_ROOT=$use_root" >> "$INSTALLER_CONFIG"
    
    if [ $use_root -eq 0 ]; then
        local root_password
        root_password=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                          --title "\Z1Set Root Password\Zn" \
                          --passwordbox "\n\Z3Enter root password:\Zn" \
                          8 50 \
                          3>&1 1>&2 2>&3)
        
        local root_password_confirm
        root_password_confirm=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                                  --title "\Z1Confirm Root Password\Zn" \
                                  --passwordbox "\n\Z3Confirm root password:\Zn" \
                                  8 50 \
                                  3>&1 1>&2 2>&3)
        
        while [ "$root_password" != "$root_password_confirm" ]; do
            dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                   --title "\Z1Password Error\Zn" \
                   --msgbox "\n\Z1Root passwords do not match. Please try again.\Zn" \
                   7 50
            
            root_password=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                              --title "\Z1Set Root Password\Zn" \
                              --passwordbox "\n\Z3Enter root password:\Zn" \
                              8 50 \
                              3>&1 1>&2 2>&3)
            
            root_password_confirm=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                                      --title "\Z1Confirm Root Password\Zn" \
                                      --passwordbox "\n\Z3Confirm root password:\Zn" \
                                      8 50 \
                                      3>&1 1>&2 2>&3)
        done
        
        local hashed_root_password=$(echo "$root_password" | mkpasswd -m sha-512 -s)
        echo "ROOT_PASSWORD=$hashed_root_password" >> "$INSTALLER_CONFIG"
    fi
}

select_packages() {
    print_header
    echo -e "${BLUE}Selecting additional packages...${NC}"
    
    # Multi-select dialog for package categories
    local selections=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                            --title "\Z1Software Selection\Zn" \
                            --checklist "\n\Z3Select additional software to install:\Zn" \
                            17 70 10 \
                            "gaming" "Gaming packages (Steam, Lutris, etc.)" OFF \
                            "programming" "Development tools and languages" OFF \
                            "multimedia" "Media creation and editing tools" OFF \
                            "office" "Office and productivity tools" OFF \
                            "daily" "Everyday applications" ON \
                            "browser" "Web browsers" ON \
                            "security" "Security and privacy tools" OFF \
                            "networking" "Advanced networking tools" OFF \
                            "virtualization" "Virtualization software" OFF \
                            "utils" "System utilities and tools" ON \
                            3>&1 1>&2 2>&3)
    
    echo "PACKAGE_SELECTION=\"$selections\"" >> "$INSTALLER_CONFIG"
    
    # For each selected category, add packages to the package list
    for category in $selections; do
        case $category in
            gaming)
                echo "steam lutris gamemode mangohud discord" >> "$SELECTED_PACKAGES_FILE"
                ;;
            programming)
                echo "git vscode gcc python3 nodejs rust" >> "$SELECTED_PACKAGES_FILE"
                ;;
            multimedia)
                echo "gimp kdenlive inkscape blender audacity" >> "$SELECTED_PACKAGES_FILE"
                ;;
            office)
                echo "libreoffice thunderbird keepassxc nextcloud-client" >> "$SELECTED_PACKAGES_FILE"
                ;;
            daily)
                echo "vlc telegram-desktop spotify" >> "$SELECTED_PACKAGES_FILE"
                ;;
            browser)
                echo "firefox chromium" >> "$SELECTED_PACKAGES_FILE"
                ;;
            security)
                echo "gnupg password-store yubikey-manager" >> "$SELECTED_PACKAGES_FILE"
                ;;
            networking)
                echo "wireguard-tools openssh wireshark" >> "$SELECTED_PACKAGES_FILE"
                ;;
            virtualization)
                echo "qemu virt-manager docker-compose" >> "$SELECTED_PACKAGES_FILE"
                ;;
            utils)
                echo "ripgrep fd exa bat htop neofetch unzip" >> "$SELECTED_PACKAGES_FILE"
                ;;
        esac
    done
    
    # Show summary of selected packages
    local package_summary=$(cat "$SELECTED_PACKAGES_FILE" | tr ' ' '\n' | sort | uniq | tr '\n' ' ')
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Package Summary\Zn" \
           --msgbox "\n\Z3You've selected the following packages to install:\Zn\n\n$package_summary" \
           13 70
}

timezone_and_locale() {
    print_header
    echo -e "${BLUE}Setting timezone and locale...${NC}"
    
    # Get timezone options from system
    local timezone_options=()
    local regions=$(ls -1 /usr/share/zoneinfo/ | grep -v -E "posix|right|zone.tab" | sort)
    
    for region in $regions; do
        if [[ -d "/usr/share/zoneinfo/$region" ]]; then
            local cities=$(ls -1 "/usr/share/zoneinfo/$region" | sort)
            for city in $cities; do
                if [[ ! -d "/usr/share/zoneinfo/$region/$city" ]]; then
                    timezone_options+=("$region/$city" "$region/$city")
                fi
            done
        fi
    done
    
    # Or use a simplified list if the system list is not available
    if [ ${#timezone_options[@]} -eq 0 ]; then
        timezone_options=(
            "America/New_York" "Eastern Time" 
            "America/Chicago" "Central Time"
            "America/Denver" "Mountain Time"
            "America/Los_Angeles" "Pacific Time"
            "Europe/London" "UK Time" 
            "Europe/Berlin" "Central European Time" 
            "Europe/Moscow" "Moscow Time"
            "Asia/Dubai" "Gulf Time"
            "Asia/Tokyo" "Japan Time"
            "Asia/Shanghai" "China Time"
            "Australia/Sydney" "Australia Eastern Time"
            "Pacific/Auckland" "New Zealand Time"
        )
    fi
    
    local timezone
    timezone=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                    --title "\Z1Timezone\Zn" \
                    --menu "\n\Z3Select your timezone:\Zn" \
                    20 60 12 \
                    "${timezone_options[@]}" \
                    3>&1 1>&2 2>&3)
    
    echo "TIMEZONE=$timezone" >> "$INSTALLER_CONFIG"
    
    # Locale selection
    local locale_options=(
        "en_US.UTF-8" "English (US)" 
        "en_GB.UTF-8" "English (UK)" 
        "de_DE.UTF-8" "German" 
        "fr_FR.UTF-8" "French" 
        "es_ES.UTF-8" "Spanish" 
        "it_IT.UTF-8" "Italian"
        "ru_RU.UTF-8" "Russian"
        "zh_CN.UTF-8" "Chinese (Simplified)"
        "ja_JP.UTF-8" "Japanese"
        "ko_KR.UTF-8" "Korean"
    )
    
    local locale
    locale=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                  --title "\Z1Locale\Zn" \
                  --menu "\n\Z3Select your locale:\Zn" \
                  15 60 10 \
                  "${locale_options[@]}" \
                  3>&1 1>&2 2>&3)
    
    echo "LOCALE=$locale" >> "$INSTALLER_CONFIG"
    
    # Keyboard layout
    local keyboard_options=(
        "us" "US English" 
        "uk" "UK English" 
        "de" "German" 
        "fr" "French" 
        "es" "Spanish" 
        "it" "Italian"
        "ru" "Russian"
        "jp" "Japanese"
    )
    
    local keyboard
    keyboard=$(dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
                    --title "\Z1Keyboard Layout\Zn" \
                    --menu "\n\Z3Select your keyboard layout:\Zn" \
                    15 60 8 \
                    "${keyboard_options[@]}" \
                    3>&1 1>&2 2>&3)
    
    echo "KEYBOARD_LAYOUT=$keyboard" >> "$INSTALLER_CONFIG"
}

installation_summary() {
    print_header
    source "$INSTALLER_CONFIG"
    
    # Create a summary of all selected options
    local summary="Installation Summary:

- Disk: /dev/$INSTALL_DISK
- Partitioning: $PARTITION_METHOD
- Hostname: $HOSTNAME
- Username: $USERNAME
- Desktop Environment: KDE Plasma 6
- Timezone: $TIMEZONE
- Locale: $LOCALE
- Keyboard: $KEYBOARD_LAYOUT
"
    
    if [ -n "$PACKAGE_SELECTION" ]; then
        summary="$summary- Additional Software: $PACKAGE_SELECTION"
    fi
    
    if [ -n "$BLOOM_PROJECT_ROOT" ]; then
        summary="$summary
- Using Bloom Nix project structure: Yes"
    fi
    
    # Show summary and ask for confirmation
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Installation Summary\Zn" \
           --yesno "\n\Z3$summary\Zn\n\nProceed with installation?" \
           20 70
    
    local choice=$?
    if [ $choice -ne 0 ]; then
        dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
               --title "\Z1Installation Cancelled\Zn" \
               --msgbox "\n\Z3Installation has been cancelled. No changes were made to your system.\Zn" \
               7 60
        clear
        exit 0
    fi
}

perform_installation() {
    print_header
    echo -e "${BLUE}${BOLD}Starting installation...${NC}"
    source "$INSTALLER_CONFIG"
    
    # Create progress gauge
    (
        echo "10"; sleep 1
        echo "XXX"
        echo "Preparing disk /dev/$INSTALL_DISK..."
        echo "Partitioning and formatting disk..."
        echo "XXX"
        
        # Step 1: Partition the disk if using automatic partitioning
        if [ "$PARTITION_METHOD" = "auto" ]; then
            # For automated partitioning with UEFI
            if [ "$IS_UEFI" = "1" ]; then
                echo "Creating UEFI partitions..."
                # Create GPT partition table
                parted -s /dev/$INSTALL_DISK mklabel gpt
                
                # Create EFI partition (512MB)
                parted -s /dev/$INSTALL_DISK mkpart primary fat32 1MiB 513MiB
                parted -s /dev/$INSTALL_DISK set 1 esp on
                
                # Create root partition (rest of disk)
                parted -s /dev/$INSTALL_DISK mkpart primary ext4 513MiB 100%
                
                # Format partitions
                mkfs.fat -F32 /dev/${INSTALL_DISK}1
                mkfs.ext4 -F /dev/${INSTALL_DISK}2
                
                # Store partition info
                echo "BOOT_PARTITION=${INSTALL_DISK}1" >> "$INSTALLER_CONFIG"
                echo "ROOT_PARTITION=${INSTALL_DISK}2" >> "$INSTALLER_CONFIG"
            else
                # For BIOS systems
                echo "Creating BIOS partitions..."
                # Create MBR partition table
                parted -s /dev/$INSTALL_DISK mklabel msdos
                
                # Create boot partition (1MB)
                parted -s /dev/$INSTALL_DISK mkpart primary 1MiB 2MiB
                parted -s /dev/$INSTALL_DISK set 1 boot on
                
                # Create root partition (rest of disk)
                parted -s /dev/$INSTALL_DISK mkpart primary 2MiB 100%
                
                # Format root partition
                mkfs.ext4 -F /dev/${INSTALL_DISK}2
                
                # Store partition info
                echo "BOOT_PARTITION=${INSTALL_DISK}1" >> "$INSTALLER_CONFIG"
                echo "ROOT_PARTITION=${INSTALL_DISK}2" >> "$INSTALLER_CONFIG"
            fi
        else
            # For manual partitioning, we use the already selected partitions
            # Format partitions as needed
            if [ "$IS_UEFI" = "1" ]; then
                mkfs.fat -F32 /dev/$BOOT_PARTITION
            fi
            
            mkfs.ext4 -F /dev/$ROOT_PARTITION
            
            if [ -n "$SWAP_PARTITION" ]; then
                mkswap /dev/$SWAP_PARTITION
                swapon /dev/$SWAP_PARTITION
            fi
        fi
        
        echo "20"; sleep 1
        echo "XXX"
        echo "Mounting filesystems..."
        echo "Preparing installation environment..."
        echo "XXX"
        
        # Mount the partitions
        mkdir -p /mnt
        mount /dev/$ROOT_PARTITION /mnt
        
        if [ "$IS_UEFI" = "1" ]; then
            mkdir -p /mnt/boot/efi
            mount /dev/$BOOT_PARTITION /mnt/boot/efi
        fi
        
        echo "30"; sleep 1
        echo "XXX"
        echo "Installing base system..."
        echo "This may take a while..."
        echo "XXX"
        
        # Generate hardware configuration
        nixos-generate-config --root /mnt
        
        echo "40"; sleep 1
        echo "XXX"
        echo "Copying project files..."
        echo "Setting up system configuration..."
        echo "XXX"
        
        # If we have a project structure, copy it to the installation
        mkdir -p /mnt/etc/nixos/bloom-nix
        if [ -n "$BLOOM_PROJECT_ROOT" ]; then
            # Copy project files to the installation
            copy_project_files "/mnt/etc/nixos/bloom-nix"
            
            # Create a flake-based configuration that imports the project files
            cat > /mnt/etc/nixos/configuration.nix << EOF
# This is a NixOS configuration that imports the Bloom Nix project
# Generated by the Bloom Nix installer

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan
      ./hardware-configuration.nix
      
      # Import the desktop configuration from the Bloom Nix project
      ./bloom-nix/hosts/desktop
    ];

  # Basic system configuration
  networking.hostName = "$HOSTNAME";
  time.timeZone = "$TIMEZONE";
  i18n.defaultLocale = "$LOCALE";
  console.keyMap = "$KEYBOARD_LAYOUT";

  # User account
  users.users.$USERNAME = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "$USER_PASSWORD";
    home = "/home/$USERNAME";
    description = "$FULLNAME";
  };
  
  # Root account
  users.users.root.hashedPassword = ${[ "$USE_ROOT" = "0" ] && "\"$ROOT_PASSWORD\"" || "null" };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "24.05"; # Use appropriate version
}
EOF
        else
            # Create a standard configuration.nix file
            cat > /mnt/etc/nixos/configuration.nix << EOF
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page.

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader if UEFI, otherwise GRUB
  boot.loader.systemd-boot.enable = ${IS_UEFI};
  boot.loader.efi.canTouchEfiVariables = ${IS_UEFI};
  ${[ "$IS_UEFI" = "0" ] && "boot.loader.grub.enable = true;" || ""}
  ${[ "$IS_UEFI" = "0" ] && "boot.loader.grub.device = \"/dev/$INSTALL_DISK\";" || ""}

  # Networking
  networking.hostName = "$HOSTNAME";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "$TIMEZONE";

  # Select internationalisation properties.
  i18n.defaultLocale = "$LOCALE";
  console.keyMap = "$KEYBOARD_LAYOUT";

  # Enable KDE Plasma 6
  services.xserver.enable = true;
  services.xserver.layout = "$KEYBOARD_LAYOUT";
  services.desktopManager.plasma6.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.wayland.enable = true;

  # Define a user account
  users.users.$USERNAME = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPassword = "$USER_PASSWORD";
    home = "/home/$USERNAME";
    description = "$FULLNAME";
  };
  
  # Enable sudo access
  security.sudo.wheelNeedsPassword = true;
  
  # Enable or disable root account
  users.users.root.hashedPassword = ${[ "$USE_ROOT" = "0" ] && "\"$ROOT_PASSWORD\"" || "null" };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    vim
    wget
    git
    htop
    firefox
    
    # Selected packages from installation
    $(cat $SELECTED_PACKAGES_FILE)
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
}
EOF
        fi
        
        echo "70"; sleep 1
        echo "XXX"
        echo "Installing bootloader..."
        echo "Configuring system..."
        echo "XXX"
        
        # Run the NixOS installation command
        nixos-install --no-root-passwd
        
        echo "85"; sleep 1
        echo "XXX"
        echo "Installing packages..."
        echo "Setting up user accounts..."
        echo "XXX"
        
        # Perform any final configurations
        
        echo "95"; sleep 1
        echo "XXX"
        echo "Finalizing installation..."
        echo "Cleaning up..."
        echo "XXX"
        
        # Unmount all filesystems
        umount -R /mnt || true
        
        echo "100"; sleep 1
        echo "XXX"
        echo "Installation complete!"
        echo "Your system is ready to use."
        echo "XXX"
        
    ) | dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
               --title "\Z1Installing $DISTRO_NAME\Zn" \
               --gauge "Preparing..." \
               10 70 0
    
    # Show completion message
    dialog $DIALOG_OPTS --backtitle "$DIALOG_TITLE" \
           --title "\Z1Installation Complete\Zn" \
           --msgbox "\n\Z3$DISTRO_NAME has been successfully installed!\Zn\n\nYou can now restart your computer to begin using your new system.\n\nUsername: $USERNAME\nHostname: $HOSTNAME\n\nThank you for choosing $DISTRO_NAME!" \
           12 60
}

#===============================================================================
# Main Installation Sequence
#===============================================================================

main() {
    # Enable dialog mouse support
    export DIALOGOPTS="--mouse"
    
    welcome_screen
    check_system_requirements
    select_disk
    setup_user_accounts
    select_packages
    timezone_and_locale
    installation_summary
    perform_installation
    
    clear
    print_header
    echo -e "${GREEN}${BOLD}Installation completed successfully!${NC}"
    echo -e "You can now reboot your system to start using $DISTRO_NAME."
    echo
    echo -e "${YELLOW}Thank you for choosing $DISTRO_NAME!${NC}"
    echo
}

# Start the installer
main
