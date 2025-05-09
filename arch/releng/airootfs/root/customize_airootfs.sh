#!/usr/bin/env bash

sudo chmod +x ~/installer.desktop && sudo mkdir ~/Desktop && mv ~/installer.desktop ~/Desktop

#!/bin/bash

# Script to install Calamares from the Arch User Repository (AUR)
# https://aur.archlinux.org/packages/calamares

set -eo pipefail # Exit on error and pipe failure

PACKAGE_NAME="calamares"
AUR_BASE_URL="https://aur.archlinux.org"
AUR_CLONE_URL="${AUR_BASE_URL}/${PACKAGE_NAME}.git"

# --- Helper Functions ---
log() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

warn() {
    echo "[WARN] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

error_exit() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1" >&2
    exit 1
}

# --- Sanity check for user ---
if [ "$(id -u)" -eq 0 ] && ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    warn "You are running this script as root, and no common AUR helper (yay/paru) was found."
    warn "For manual AUR builds, 'makepkg' must be run as a non-root user."
    warn "The script will proceed to install build dependencies and clone the repository."
    warn "You will then be instructed to switch to a non-root user to complete the build."
    echo # Blank line for readability
fi

# --- 1. Check for AUR Helpers ---
if command -v yay &>/dev/null; then
    log "Found AUR helper 'yay'. Using it to install ${PACKAGE_NAME}."
    # If root invoked this script via sudo, SUDO_USER will be the original user.
    # yay is smart enough to handle this, or will ask for sudo password if run by non-root.
    # If root directly, yay might use 'nobody' or its own handling.
    if yay -S --noconfirm "$PACKAGE_NAME"; then
        log "${PACKAGE_NAME} successfully installed using yay."
        exit 0
    else
        error_exit "Failed to install ${PACKAGE_NAME} using yay."
    fi
fi

if command -v paru &>/dev/null; then
    log "Found AUR helper 'paru'. Using it to install ${PACKAGE_NAME}."
    if paru -S --noconfirm "$PACKAGE_NAME"; then
        log "${PACKAGE_NAME} successfully installed using paru."
        exit 0
    else
        error_exit "Failed to install ${PACKAGE_NAME} using paru."
    fi
fi

log "No common AUR helper (yay/paru) found. Proceeding with manual AUR build process."
echo # Blank line for readability

# --- 2. Manual AUR Build Process ---
# Install necessary tools: git and base-devel group (for makepkg, compilers, etc.)
log "Ensuring 'git' and 'base-devel' group are installed..."
if [ "$(id -u)" -eq 0 ]; then
    pacman -S --needed --noconfirm git base-devel || error_exit "Failed to install git/base-devel as root."
else
    sudo pacman -S --needed --noconfirm git base-devel || error_exit "Failed to install git/base-devel. Ensure you have sudo privileges."
fi
log "'git' and 'base-devel' are present."

# Define build directory
# If run as root, place in /tmp or /opt. If non-root, in user's home.
if [ "$(id -u)" -eq 0 ]; then
    BUILD_PARENT_DIR="/tmp" # Or consider /opt/aur_builds
else
    BUILD_PARENT_DIR="$HOME/aur_builds"
    mkdir -p "$BUILD_PARENT_DIR" || error_exit "Failed to create build directory: ${BUILD_PARENT_DIR}"
fi
CLONE_DIR="${BUILD_PARENT_DIR}/${PACKAGE_NAME}_aur_$(date +%s)" # Unique directory to avoid conflicts

log "Cloning ${PACKAGE_NAME} AUR repository into ${CLONE_DIR}..."
# Clean up if directory somehow exists (though unique name should prevent)
if [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
fi
if ! git clone "$AUR_CLONE_URL" "$CLONE_DIR"; then
    error_exit "Failed to clone AUR repository: ${AUR_CLONE_URL}"
fi
log "Repository cloned successfully."

# Change ownership if script is run by root and SUDO_USER is set
# This helps the actual user (who used sudo) to own the files.
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    log "Changing ownership of ${CLONE_DIR} to user '${SUDO_USER}'."
    if ! chown -R "${SUDO_USER}:${SUDO_USER}" "${CLONE_DIR}"; then # Assuming primary group is same as username
        warn "Failed to change ownership of ${CLONE_DIR} to ${SUDO_USER}. Manual chown might be needed."
    fi
fi

# Instructions or execution based on user
if [ "$(id -u)" -eq 0 ]; then
    # Script is being run as root
    log "The ${PACKAGE_NAME} AUR repository has been cloned to: ${CLONE_DIR}"
    warn "IMPORTANT: 'makepkg' must not be run as root."
    log "Please switch to a non-root user to build and install the package."
    echo # Blank line
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        log "If you are managing the system for user '${SUDO_USER}', they can now run:"
        echo "  cd \"${CLONE_DIR}\""
        echo "  makepkg -si --noconfirm"
    else
        log "You will need to use a non-root user that has sudo privileges."
        log "Example commands for a non-root user 'youruser':"
        echo "  sudo chown -R youruser:yourgroup \"${CLONE_DIR}\"  # (If needed, replace youruser:yourgroup)"
        echo "  su - youruser -c \"cd '${CLONE_DIR}' && makepkg -si --noconfirm\""
        echo "  # OR, login as 'youruser' and then:"
        echo "  # cd \"${CLONE_DIR}\""
        echo "  # makepkg -si --noconfirm"
    fi
    echo # Blank line
    log "Build process not completed automatically because the script was run as root without an AUR helper."
else
    # Script is being run as a non-root user
    log "Changing current directory to ${CLONE_DIR}..."
    cd "$CLONE_DIR" || error_exit "Failed to change directory to ${CLONE_DIR}."

    log "Starting 'makepkg' to build and install ${PACKAGE_NAME}..."
    log "This will install dependencies using 'sudo' and then the package itself."
    # -s: sync/install dependencies from official repositories
    # -i: install the package using 'pacman -U' after successful build
    # --noconfirm: attempt to answer yes to all prompts (from makepkg and from pacman for dependencies/installation)
    if makepkg -si --noconfirm; then
        log "${PACKAGE_NAME} successfully built and installed."
    else
        error_exit "makepkg process failed. Please check the output for errors and try to resolve them manually in '${CLONE_DIR}'."
    fi
fi

exit 0

