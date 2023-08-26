# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.17

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DDCLIENT_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="saarg"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    gcc \
    make \
    wget

RUN \
  apk --no-cache add automake autoconf

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    vim \
    bind-tools \
    inotify-tools \
    perl \
    perl-digest-sha1 \
    perl-io-socket-inet6 \
    perl-io-socket-ssl \
    perl-json && \
  echo "***** install perl modules ****" && \
  curl -L http://cpanmin.us | perl - App::cpanminus && \
  cpanm \
    Data::Validate::IP \
    JSON::Any

RUN \    
  echo "**** install ddclient ****" && \
  curl -o /tmp/ddclient.zip -L \
    "https://github.com/ddclient/ddclient/archive/refs/heads/master.zip" && \
  unzip /tmp/ddclient.zip -o -d /tmp/ && \
  cd /tmp/ddclient-master/ && \
  /tmp/ddclient-master/autogen && \
  /tmp/ddclient-master/configure --prefix=/usr --sysconfdir=/etc/ddclient --localstatedir=/var && \
  make && \
  make VERBOSE=1 check && \
  make install && \
  rm /usr/bin/ddclient && \
  ln -s /usr/bin/ddclient.in /usr/bin/ddclient && \
  mkdir -p /etc/ddclient/ && \
  cp /tmp/ddclient-master/sample-get-ip-from-fritzbox /etc/ddclient/get-ip-from-fritzbox && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /config/.cpanm \
    /root/.cpanm \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
