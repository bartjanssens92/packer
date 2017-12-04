#!/bin/bash

# Get the puppetlabs repo
rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm

# Install the package
yum clean all
yum install puppet -y

# Remove the repository
yum remove puppet5-release -y
