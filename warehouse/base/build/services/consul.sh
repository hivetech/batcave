#! /bin/bash
set -e
source /build/buildconfig
set -x

readonly PACKAGE="0.3.0_linux_amd64.zip"

wget https://dl.bintray.com/mitchellh/consul/$PACKAGE
unzip $PACKAGE && rm $PACKAGE
mv consul /usr/local/bin/ && \
  mkdir /etc/consul.d && \
  mkdir /etc/service/consul && \
  mv /build/processes/startup-consul /etc/service/consul/run
