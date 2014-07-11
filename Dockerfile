# hivetech/batcave image
#
# Docker run -d --name batcave \
#   -e CONSUL_HOST=192.168.0.19 \
#   -e REDIS_HOST=172.17.0.23 \
#   hivetech/batcave
# VERSION 0.0.2

# Administration ---------------------------------------
# https://github.com/phusion/passenger-docker
FROM hivetech/batcave:base
MAINTAINER Xavier Bruhiere <xavier.bruhiere@gmail.com>

# Install docker ---------------------------------------
#curl -s https://get.docker.io/ubuntu/ | sh
ADD https://get.docker.io/builds/Linux/x86_64/docker-latest /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker

# Install Batcave --------------------------------------
ADD build /build
ADD . /app
RUN cd /app && make install
RUN mkdir /etc/service/batcave && mkdir /etc/service/worker && \
  mv /build/startup-batcave /etc/service/batcave/run && \
  mv /build/startup-worker /etc/service/worker/run

EXPOSE 22
