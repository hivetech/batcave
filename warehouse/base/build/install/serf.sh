#! /bin/bash
set -e
source /build/buildconfig
set -x

readonly PACKAGE="0.5.0_linux_amd64.zip"

wget https://dl.bintray.com/mitchellh/serf/$PACKAGE
unzip $PACKAGE && rm $PACKAGE
mv serf /usr/local/bin/ && mkdir /etc/service/serf
