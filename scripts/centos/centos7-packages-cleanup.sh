#!/bin/bash

# Reference:
# https://wiki.centos.org/HowTos/Virtualization/VirtualBox/CentOSguest

yum remove epel-release -y
yum remove gcc kernel-devel kernel-headers dkms make bzip2 perl -y

reboot
