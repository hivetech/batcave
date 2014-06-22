#! /bin/bash
set -e
source /build/buildconfig
set -x

readonly PACKAGE="0.5.0_linux_amd64.zip"

$minimal_apt_get_install unzip
wget https://dl.bintray.com/mitchellh/serf/$PACKAGE
unzip $PACKAGE && rm $PACKAGE
mv serf /usr/local/bin/ && mkdir /etc/service/serf

# Requirements
$minimal_apt_get_install golang libssl-dev zlib1g-dev
git clone git://github.com/elasticsearch/logstash-forwarder.git /tmp/logstash-forwarder
sed -i 's/|syslog.LOG_DAEMON//g' /tmp/logstash-forwarder/syslog.go
cd /tmp/logstash-forwarder && go build

mv /tmp/logstash-forwarder/logstash-forwarder /usr/local/bin && \
  mkdir /etc/service/logstash-forwarder && \
  mv /build/processes/startup-logstash-forwarder /etc/service/logstash-forwarder/run
