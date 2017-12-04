#!/bin/bash

# The repo url
baseurl=''

# Check that it's not empty
if [[ $baseurl == '' ]]; then echo "No repository provided, quiting!"; exit 1; fi

# Need to add the rhel repos first
cat << EOFrhelrepo > /etc/yum.repos.d/rhelrepos.repo
[rhelrepo]
name=rhelrepo
baseurl=$baseurl
enabled=1
gpgcheck=0
sslverify=0
EOFrhelrepo

# And the epel repo
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Install the needed packages
yum clean all
yum install gcc kernel-devel kernel-headers dkms make bzip2 perl -y
shutdown -r now
