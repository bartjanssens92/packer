#!/usr/vin/env bash

if cat /etc/redhat-release | grep ' 6' &>/dev/null
then
  # CentOS 6.8 (Final)
  echo "Centos 6"
  rpm -ivh https://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-10.noarch.rpm
else
  rpm -ivh https://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-12.noarch.rpm
fi

sudo yum clean all

# Client
sudo yum install puppet -y

