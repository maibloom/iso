#!/bin/bash
# changer.sh

WORK_DIR="$HOME/maibloom-temp/work"
OUT_DIR="$HOME/maibloom-temp/out"

sudo mkdir -p "$WORK_DIR"
sudo mkdir -p "$OUT_DIR"

sudo mkarchiso -v \
  -w "$WORK_DIR" \
  -o "$OUT_DIR" .
