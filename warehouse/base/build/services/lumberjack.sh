#! /bin/bash
set -e
source /build/buildconfig
set -x

# Requirements
#$minimal_apt_get_install golang libssl-dev zlib1g-dev
$minimal_apt_get_install libssl-dev zlib1g-dev
git clone git://github.com/elasticsearch/logstash-forwarder.git /tmp/logstash-forwarder
# Compile and install lumberjack
sed -i 's/|syslog.LOG_DAEMON//g' /tmp/logstash-forwarder/syslog.go
cd /tmp/logstash-forwarder && go build && cd
mv /tmp/logstash-forwarder/logstash-forwarder /usr/local/bin
rm -r /tmp/logstash-forwarder

# Setup runit service
mkdir /etc/service/logstash-forwarder && \
mv /build/processes/startup-logstash-forwarder /etc/service/logstash-forwarder/run
