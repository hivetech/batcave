FROM hivetech/batcave:base
MAINTAINER hackliff "xavier.bruhiere@gmail.com"

ADD ./stack/ /build/stack
#RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive /build/stack/prepare
RUN rm -rf /var/lib/apt/lists/* && apt-get clean
