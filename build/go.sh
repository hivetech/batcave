#! /bin/bash

# FIXME code.google.com/p/go.crypto/ssh/cipher.go:241: undefined: cipher.AEAD
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -qy build-essential curl git bzr mercurial
curl -s https://go.googlecode.com/files/go1.2.1.src.tar.gz | tar -v -C /usr/local -xz
cd /usr/local/go/src && ./make.bash --no-clean 2>&1
