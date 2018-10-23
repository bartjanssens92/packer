#!/usr/bin/env bash

mkdir /tmp/virtualbox
VERSION=$(cat /home/vagrant/.vbox_version)

## Current running kernel on Fedora, CentOS 7/6 and Red Hat (RHEL) 7/6 ##
KERN_DIR=/usr/src/kernels/`uname -r`

## Export KERN_DIR ##
export KERN_DIR

# Line for if the iso is not found
# Could be in a different location
echo "ISO's found in /"
find / -path /proc -prune -o -name '*.iso'

mount -o loop /home/vagrant/VBoxGuestAdditions_$VERSION.iso /tmp/virtualbox
sudo sh /tmp/virtualbox/VBoxLinuxAdditions.run
umount /tmp/virtualbox
rmdir /tmp/virtualbox
rm /home/vagrant/*.iso
