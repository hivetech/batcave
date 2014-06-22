#! /bin/bash

function run_central_logs() {
  docker run -d --name logstash \
    -p 9200:9200 -p 9292:9292 quay.io/hackliff/logstash
}

function run_forwarder() {
  ./logstash-forwarder -config /tmp/lumberjack.json
}

function run_demo_base() {
  docker run -d --name base \
    -e NODE_ID=devenv \
    -e SALT_MASTER=192.168.0.11 \
    -e CONSUL_MASTER=192.168.0.11 \
    -e LOGSTASH_SERVER=172.17.0.3 \
    hivetech/base
}

# No use if relying on hivy container
function run_on_hivy() {
  salt-master -l debug -c /etc/salt
  consul agent -server -bootstrap \
    -data-dir /tmp/consul \
    -node master \
    -client 0.0.0.0
}

function run_hivy() {
  docker run -d --name mongo \
    -p 27017:27017 \
    -p 28017:28017 \
    dockerfile/mongodb --rest

  docker run -d --name hivy \
    -e MONGODB_HOST=172.17.0.3 \
    -e MONGODB_PORT=27017 \
    hivetech/hivy /sbin/my_init --enable-insecure-key
}
