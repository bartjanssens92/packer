#!/usr/vin/env bash

echo 'Create the .ssh directory'
mkdir /home/vagrant/.ssh
echo 'Get the vagrant.pub key'
if curl -h&>/dev/null
then
  curl -O -s 'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub'
else
  wget 'https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub'
fi
echo 'Move the vagrant.pub to authorized_keys'
mv vagrant.pub /home/vagrant/.ssh/authorized_keys
echo 'Set the correct permissions'
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod -R go-rwsx /home/vagrant/.ssh
echo 'Set the sudo config for the vagrant user'
echo 'vagrant  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
