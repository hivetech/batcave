#!/bin/bash
set -e
source /build/buildconfig
set -x

$minimal_apt_get_install python-software-properties
add-apt-repository -y ppa:saltstack/salt
apt-get update -y
$minimal_apt_get_install salt-minion
