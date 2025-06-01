#!/bin/bash
# fix-installer-build.sh
# Run from your releng directory

# 1. Update pacman.conf
cat >> pacman.conf <<'EOL'

# Preferred providers to avoid prompts
[options]
DefaultPackages = iptables-nft phonon-qt6-mpv pyside6 tesseract-data-eng
NoExtract = usr/lib/libxtables.so* usr/lib/libnftables.so* usr/lib/qt/plugins/phonon4qt5_backend/*
EOL

# 2. Clean up packages list
sed -i '/python-customtkinter/d' packages.x86_64
sed -i '/python-streamlit/d' packages.x86_64

# 3. Add Python build essentials
echo -e "\n# Python toolchain" >> packages.x86_64
echo "python-pip" >> packages.x86_64
echo "python-setuptools" >> packages.x86_64

# 4. Update customization script
cat >> airootfs/root/customize_airootfs.sh <<'EOL'

# Install Python packages
pip install --break-system-packages \
    customtkinter \
    streamlit
EOL

# 5. Build command with forced providers
sudo mkarchiso -v \
  --noconfirm \
  --needed \
  -D "iptables-nft,phonon-qt6-mpv,pyside6,tesseract-data-eng" \
  -w /tmp/archiso-work \
  -o /tmp/archiso-out .

# 6. Verify Python packages in built ISO
echo "Verifying Python packages in the ISO..."
sudo arch-chroot /tmp/archiso-work/x86_64/airootfs pip list | grep -E 'customtkinter|streamlit'

echo "Build complete! Check /tmp/archiso-out for the ISO"

