# hivetech/batcave:base image
# Base node for hivy-compliant docker images deployment
# VERSION 0.0.3

# Administration
FROM phusion/passenger-customizable:0.9.10
MAINTAINER hackliff "xavier.bruhiere@gmail.com"

# Set correct environment variables.
ENV HOME /root
ADD build /build
ADD certs /opt/certs

# Build system and git.
RUN apt-get update -y && \
  /build/utilities.sh

# Python support - Usefull here for ansible and saltstack
RUN /build/python.sh

# -------------------------------------------------------------- #
# ----    Consul installation   -------------------------------- #
# -------------------------------------------------------------- #
RUN /build/services/consul.sh

# -------------------------------------------------------------- #
# ----    Salt-minion installation    -------------------------- #
# -------------------------------------------------------------- #
#RUN /build/salt-minion.sh
#RUN mkdir /etc/service/salt-minion
#ADD processes/startup-salt-minion /etc/service/salt-minion/run

# -------------------------------------------------------------- #
# ----    Collectd installation    ----------------------------- #
# -------------------------------------------------------------- #
#RUN apt-get install -y --no-install-recommends collectd && \
#mkdir /etc/service/collectd && \
#mv /build/config/collectd.conf /etc/collectd/collectd.conf
#ADD processes/startup-collectd /etc/service/collectd/run
# -------------------------------------------------------------- #
# ----    Glances installation    ------------------------------ #
# -------------------------------------------------------------- #
#RUN pip install --upgrade Glances && \
#mkdir /etc/service/glances
#ADD processes/startup-glances /etc/service/glances/run

# -------------------------------------------------------------- #
# ----   Lumberjack installation   ----------------------------- #
# -------------------------------------------------------------- #
# First we need go
RUN mkdir /go && /build/go.sh
ENV PATH /usr/local/go/bin:/go/bin:$PATH
ENV GOPATH /go
# https://github.com/elasticsearch/logstash-forwarder
RUN /build/services/lumberjack.sh

# Install the process wrapper
RUN go get -t github.com/hivetech/envconsul

# Clean up APT when done.
RUN /build/cleanup.sh

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Expose serf, and ssh / ansible, Glances ports
EXPOSE 7946 7373 22 61209
