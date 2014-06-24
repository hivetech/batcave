#! /bin/bash
set -e
source /build/buildconfig
set -x


function install_from_source() {
  local GO_VERSION=$1
  curl -s https://storage.googleapis.com/golang/${GO_VERSION}.src.tar.gz | tar -v -C /usr/local -xz
  cd /usr/local/go/src && ./make.bash --no-clean 2>&1

  # Clean up a bit
  rm -r /usr/local/go/{misc,doc,test,api,include}
}

function install_package() {
  $minimal_apt_get_install python-software-properties
  add-apt-repository ppa:duh/golang && apt-get update
  $minimal_apt_get_install golang
}

install_from_source "go1.3"
