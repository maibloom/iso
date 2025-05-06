#!/bin/bash
# changer.sh - Final working version

# Clean duplicate entries
#sort -u packages.x86_64 -o packages.x86_64

# Build command
sudo mkarchiso -v \
  -w /home/purple/local-temp/work/ \
  -o /home/purple/local-temp/out/ .


