#!/bin/bash

echo 'clean'
apt-get clean
echo 'update'
apt-get update

# Client
echo 'install puppet'
apt-get install puppet-common -y
echo 'installed puppet'
