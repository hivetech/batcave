#! /bin/bash
set -e
source /build/buildconfig
set -x

readonly PACKAGE="0.3.0_linux_amd64.zip"

wget https://dl.bintray.com/mitchellh/consul/$PACKAGE
unzip $PACKAGE && rm $PACKAGE
mv consul /usr/local/bin/
# Create the configuration directory
mkdir /etc/consul.d
# Prepare runit init system
mkdir /etc/service/consul
mv /build/processes/startup-consul /etc/service/consul/run
