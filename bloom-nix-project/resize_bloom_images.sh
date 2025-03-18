#!/bin/bash

# Image Resizing Script for Bloom Nix
# This script automatically resizes and optimizes all images in your Bloom Nix project

# Set text colors for nice output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Bloom Nix Image Optimization Tool ===${NC}"
echo "This script will resize and optimize all images in your project."

# Install dependencies
echo -e "${YELLOW}Installing required dependencies...${NC}"
sudo apt update
sudo apt install -y imagemagick pngquant jpegoptim optipng

# Create backup directory
BACKUP_DIR="./image_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Backing up original images to $BACKUP_DIR${NC}"

# Function to optimize PNG images
optimize_png() {
    local input=$1
    local output=$2
    local width=$3
    local height=$4
    
    # Create backup
    cp "$input" "$BACKUP_DIR/$(basename "$input")"
    
    echo -e "${BLUE}Processing: ${NC}$input → $width×$height"
    
    # Resize and optimize
    convert "$input" -resize "${width}x${height}" "$output.tmp"
    optipng -o2 "$output.tmp" -out "$output"
    rm "$output.tmp"
    
    # Show file size reduction
    original_size=$(du -h "$BACKUP_DIR/$(basename "$input")" | cut -f1)
    new_size=$(du -h "$output" | cut -f1)
    echo -e "${GREEN}Optimized:${NC} $original_size → $new_size"
}

# Function to optimize JPEG images
optimize_jpg() {
    local input=$1
    local output=$2
    local width=$3
    local height=$4
    
    # Create backup
    cp "$input" "$BACKUP_DIR/$(basename "$input")"
    
    echo -e "${BLUE}Processing: ${NC}$input → $width×$height"
    
    # Resize and optimize
    convert "$input" -resize "${width}x${height}" -quality 90 "$output"
    jpegoptim --max=90 "$output"
    
    # Show file size reduction
    original_size=$(du -h "$BACKUP_DIR/$(basename "$input")" | cut -f1)
    new_size=$(du -h "$output" | cut -f1)
    echo -e "${GREEN}Optimized:${NC} $original_size → $new_size"
}

echo -e "\n${YELLOW}Processing GRUB backgrounds...${NC}"
optimize_png "./branding/grub/background.png" "./branding/grub/background.png" 1920 1080
optimize_png "./branding/grub-background.png" "./branding/grub-background.png" 1920 1080
optimize_png "./branding/grub/theme/background.png" "./branding/grub/theme/background.png" 1920 1080

echo -e "\n${YELLOW}Processing splash screen...${NC}"
optimize_png "./branding/splash.png" "./branding/splash.png" 1920 1080

echo -e "\n${YELLOW}Processing desktop backgrounds...${NC}"
optimize_png "./branding/background.png" "./branding/background.png" 3840 2160
optimize_jpg "./modules/branding/wallpapers/default.jpg" "./modules/branding/wallpapers/default.jpg" 3840 2160

echo -e "\n${YELLOW}Processing logos...${NC}"
optimize_png "./branding/bloom-logo.png" "./branding/bloom-logo.png" 512 512
optimize_png "./modules/branding/bloom-logo.png" "./modules/branding/bloom-logo.png" 512 512
optimize_png "./branding/logo.png" "./branding/logo.png" 256 256

echo -e "\n${YELLOW}Processing login screen backgrounds...${NC}"
optimize_png "./branding/sddm-background.png" "./branding/sddm-background.png" 1920 1080
optimize_png "./branding/sddm-background.png.png" "./branding/sddm-background.png.png" 1920 1080
optimize_jpg "./etc/bloom-nix/backgrounds/login.jpg" "./etc/bloom-nix/backgrounds/login.jpg" 1920 1080

echo -e "\n${YELLOW}Processing Calamares installer images...${NC}"
if [ -d "./modules/installer/calamares/branding/bloom-nix" ]; then
    optimize_png "./modules/installer/calamares/branding/bloom-nix/icon.png" "./modules/installer/calamares/branding/bloom-nix/icon.png" 128 128
    optimize_png "./modules/installer/calamares/branding/bloom-nix/logo.png" "./modules/installer/calamares/branding/bloom-nix/logo.png" 100 100
    optimize_png "./modules/installer/calamares/branding/bloom-nix/welcome.png" "./modules/installer/calamares/branding/bloom-nix/welcome.png" 600 400
    
    # Process slideshow images
    for slide in ./modules/installer/calamares/branding/bloom-nix/slide*.png; do
        if [ -f "$slide" ]; then
            optimize_png "$slide" "$slide" 800 440
        fi
    done
else
    echo -e "${RED}Calamares branding directory not found. Skipping installer images.${NC}"
fi

echo -e "\n${YELLOW}Processing system icons...${NC}"
if [ -f "./etc/bloom-nix/icons/IMG_20250318_025711.png" ]; then
    # Create multi-size icons
    for size in 16 32 48 64 128; do
        outdir="./etc/bloom-nix/icons/${size}x${size}"
        mkdir -p "$outdir"
        convert "./etc/bloom-nix/icons/IMG_20250318_025711.png" -resize "${size}x${size}" "$outdir/bloom-nix.png"
        echo -e "${GREEN}Created:${NC} $size×$size icon"
    done
else
    echo -e "${RED}System icon not found. Skipping icon resizing.${NC}"
fi

echo -e "\n${GREEN}===== Image processing complete! =====${NC}"
echo -e "All images have been resized and optimized for Bloom Nix."
echo -e "Original files are backed up in: ${BLUE}$BACKUP_DIR${NC}"
echo -e "${YELLOW}Note:${NC} You may want to check each image to ensure quality meets your standards."