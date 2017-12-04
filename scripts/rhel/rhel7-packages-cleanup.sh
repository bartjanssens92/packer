#!/bin/bash

# Remove the repo file
rm /etc/yum.repos.d/rhelrepos.repo
# Remove installed packages
yum remove epel-release gcc kernel-devel kernel-headers dkms make bzip2 -y

shutdown -r now
