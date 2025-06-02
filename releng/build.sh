#!/bin/bash
# changer.sh

sudo mkdir -p maibloombuild/w/
sudo mkdir -p maibloombuild/o/

sudo mkarchiso -v \
  -w maibloombuild/w/ \
  -o maibloombuild/o/ .
