# hivetech/batcave image
# Docker run -d --name batcave -e DOCKER_HOST=tcp://192.168.0.19:4243 hivetech/batcave
# VERSION 0.0.1

# Administration ---------------------------------------
# https://github.com/phusion/passenger-docker
FROM hivetech/base
MAINTAINER Xavier Bruhiere <xavier.bruhiere@gmail.com>

# Install go (inspiration from coreos/etcd) ------------
ADD build /build
RUN mkdir /go && /build/go.sh
ENV PATH /usr/local/go/bin:/go/bin:$PATH
ENV GOPATH /go

# Install docker ---------------------------------------
ADD https://get.docker.io/builds/Linux/x86_64/docker-latest /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker

# Install Batcave --------------------------------------
ADD . /app
RUN cd /app && make install && mkdir /etc/service/batcave
ADD /build/startup-batcave /etc/service/batcave/run

EXPOSE 22
