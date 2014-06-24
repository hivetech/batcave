# Logstash
#
# logstash is a tool for managing events and logs
#
# VERSION 1.1

FROM hivetech/base
# From the work of Deni Bertovic "deni@kset.org"
MAINTAINER Xavier Bruhiere "xavier.bruhiere@gmail.com"

ENV DEBIAN_FRONTEND noninteractive
# What tag to use for lumberjack
ENV LUMBERJACK_TAG HIVE_APP
# Number of elasticsearch workers
ENV ELASTICWORKERS 1

RUN apt-get update && apt-get install -y wget openjdk-6-jre
RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-1.3.3-flatjar.jar -O /opt/logstash.jar --no-check-certificate 2>/dev/null

RUN mkdir /etc/service/logstash
ADD startup-logstash /etc/service/logstash/run

ADD collectd-types.db /opt/collectd-types.db

EXPOSE 514 5043 9200 9292 9300
