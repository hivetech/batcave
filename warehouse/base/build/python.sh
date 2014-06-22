#!/bin/bash
set -e
source /build/buildconfig
set -x

## Install Python.
#apt-get install -y python python2.7 python3 python-dev python-pip
$minimal_apt_get_install python2.7 python-dev curl
# Make sure buggy version no longer here
apt-get autoremove -y python-setuptools
# Official pip setup
curl https://bootstrap.pypa.io/get-pip.py | python
# Make it up-to-date
pip install --upgrade setuptools pip
