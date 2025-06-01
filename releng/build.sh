#!/bin/bash
# changer.sh - Final working version

# Clean duplicate entries
#sort -u packages.x86_64 -o packages.x86_64

sudo mkdir -p /tmp/maibloom-temp/work/
sudo mkdir -p /tmp/maibloom-temp/out/

# Build command
sudo mkarchiso -v \
  -w /tmp/maibloom-temp/work/ \
  -o /tmp/maibloom-temp/out/ .


