#!/usr/bin/env bash
set -eo pipefail
# TODO Parameter availalble for the user (but restricted to base images)
export BATCAVE_BASE=${BATCAVE_BASE:="hivetech/buildstep"}
export BATCAVE_ROOT=${BATCAVE_ROOT:="/tmp/repos"}
export BATCAVE_REPO=${BATCAVE_REPO:="batcave"}
[ -d $BATCAVE_ROOT ] || mkdir $BATCAVE_ROOT
[[ -f $BATCAVE_ROOT/batcaverc ]] && source $BATCAVE_ROOT/batcaverc
[[ $BATCAVE_TRACE ]] && set -x

# FIXME Not tested yet
# TODO Make it user defined
export DOCKER_HOST=${DOCKER_HOST:="unix:///var/run/docker.sock"}
alias docker="docker --host ${DOCKER_HOST}"

function log() {
  TIME=`date +"%T"`
  printf " -----> $@\n"
  printf "[ $TIME ] -----> $@\n" >> /var/log/batcave.log
}

function build_image() {
  path=$1
  commit=$2
  username=$3
  # NOTE The application tarball is on stdin
  log "Building $path ... (commit $commit)"

  APP="$1"; IMAGE="$username/$APP"; CACHE_DIR="$BATCAVE_ROOT/$APP/cache"
  log "Streaming app into $username/$APP ..."
  id=$(cat | docker run -i -a stdin ${BATCAVE_BASE} /bin/bash -c "mkdir -p /app && tar -xC /app")
  test $(docker wait $id) -eq 0
  log "Commiting $id as $IMAGE"
  docker commit $id $IMAGE > /dev/null
  [[ -d $CACHE_DIR ]] || mkdir $CACHE_DIR
  log "Building application ..."
  id=$(docker run -d -v $CACHE_DIR:/cache $IMAGE /build/stack/proxy_builder)
  docker attach $id
  test $(docker wait $id) -eq 0
  log "Commiting final $id as $IMAGE"
  docker commit $id $IMAGE > /dev/null
}

function clean_up() {
  # delete all non-running container
  docker ps -a | grep 'Exit' | awk '{print $1}' | xargs docker rm &> /dev/null &
  # delete unused images
  docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi &> /dev/null &
}

log "Cleaning up containers ..."
clean_up

log "[DEBUG] User: $RECEIVE_USER"
log "[DEBUG] Repo: $RECEIVE_REPO"
# TODO Image name: Change BATCAVE_REPO by USERNAME (Hivy compliance)
build_image $1 $2 $BATCAVE_REPO
log "Done, application cell successfully synthetize !"
