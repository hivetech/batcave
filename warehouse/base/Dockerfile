# hivetech/node image
# Base node for hivy-compliant docker images deployment
# VERSION 0.0.2
# docker run -d -name node -e SALT_MASTER=192.168.0.11 -h node hivetech/base

# Administration
FROM phusion/passenger-customizable:0.9.10

# Set correct environment variables.
ENV HOME /root
ADD build /build
ADD certs /opt/certs

# Build system and git.
# Python support - Usefull here for ansible and saltstack
RUN apt-get update -y && \
  /build/utilities.sh && \
  /build/python.sh

# -------------------------------------------------------------- #
# ----    Consul installation   -------------------------------- #
# -------------------------------------------------------------- #
RUN /build/install/consul.sh

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
# https://github.com/elasticsearch/logstash-forwarder
RUN /build/install/lumberjack.sh

# Clean up APT when done.
RUN /build/cleanup.sh

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Expose serf, and ssh / ansible, Glances ports
EXPOSE 7946 7373 22 61209
