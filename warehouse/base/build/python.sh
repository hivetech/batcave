#!/bin/bash
set -e
source /build/buildconfig
set -x

## Install Python.
#$minimal_apt_get_install python2.7 python-dev curl
$minimal_apt_get_install python2.7 python-dev
# Make sure buggy version no longer here
which python-setuptools && apt-get autoremove -y python-setuptools
# Official pip setup
#curl https://bootstrap.pypa.io/get-pip.py | python
wget -qO- https://bootstrap.pypa.io/get-pip.py | python
# Make it up-to-date
pip install --upgrade setuptools pip
