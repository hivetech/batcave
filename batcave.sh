#!/usr/bin/env bash
set -eo pipefail
set -o errexit
[[ $BATCAVE_TRACE ]] && set -x

# Magic variables
__PROGRAME__=$(basename $0)
__DIR__="$(cd "$(dirname "${0}")"; echo $(pwd))"
__BASE__="$(basename "${0}")"
__FILE__="${__DIR__}/${__BASE__}"
__ARGS__="$@"

set -o nounset


function usage() {
  cat <<- EOF
  usage: $PROGRAMME app commit

  Batcave receives the application tarball on stdin, inject it in a special
  docker container that will build it and commit the resulting image.

  It is meant to be used as the handler script for gitreceived.

  Examples:
    gitreceived -n -k ~/.ssh/github_id_rsa auth.sh batcave.sh
EOF
}

function log() {
  TIME=`date +"%T"`
  printf " -----> $@\n"
  #FIXME [ -n "$LOGFILE" ] && printf "[ $TIME ] -----> $@\n" >> $LOGFILE
}

function read_consul_parameter() {
  local readonly KEY=$1
  local readonly DEFAULT=$2
  local RESULT=$(wget -qO- http://$CONSUL_HOST:$CONSUL_PORT/v1/kv/$KEY | jq -r '.[0].Value' | base64 --decode)
  [ -n "$RESULT" ] || RESULT=$DEFAULT
  echo $RESULT
}

function build_image() {
  local path=$1; local commit=$2; local username=$3
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
  docker commit $id $IMAGE:$commit > /dev/null

  readonly SHOULD_PUSH=$(read_consul_parameter "user/push" "")
  if [[ ("$SHOULD_PUSH" != "") && (-f ~/.dockercfg) ]]; then
    log "Pushing image to repository $BATCAVE_REPO"
    docker push $IMAGE
  fi
}

function clean_up() {
  # delete all non-running container
  docker ps -a | grep 'Exit' | awk '{print $1}' | xargs docker rm &> /dev/null &
  # delete unused images
  docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi &> /dev/null &
  # delete deprecated images
  docker images | grep 'months' | awk '{print $3}' | xargs docker rmi &> /dev/null &
}

# Main (

  # TODO Get real user name
  readonly DOCKER_HOST=$(read_consul_parameter "user/docker/host" "unix:///var/run/docker.sock")
  alias docker="docker --host ${DOCKER_HOST}"

  # Specific behavior
  readonly CONSUL_HOST=${CONSUL_HOST:="localhost"}
  readonly CONSUL_PORT=${CONSUL_PORT:="8500"}
  readonly BATCAVE_ROOT=${BATCAVE_ROOT:="/tmp/repos"}
  readonly BATCAVE_BASE=$(read_consul_parameter "user/base" "hivetech/batcave:buildstep")
  readonly BATCAVE_REPO=$(read_consul_parameter "user/docker/repo" "batcave")
  [ -d $BATCAVE_ROOT ] || mkdir $BATCAVE_ROOT
  [[ -f $BATCAVE_ROOT/batcaverc ]] && source $BATCAVE_ROOT/batcaverc

  log "[DEBUG] Using $BATCAVE_BASE as image foundation"
  log "[DEBUG] Setting $BATCAVE_ROOT as Batcave root directory"
  log "[DEBUG] Using $BATCAVE_REPO as docker image repository"
  log "[DEBUG] Talking to docker at $DOCKER_HOST"

  log "[INFO] Cleaning up containers ..."
  clean_up

  log "[DEBUG] Push User: $RECEIVE_USER"
  log "[DEBUG] Push Repo: $RECEIVE_REPO"
  # TODO Image name: Change BATCAVE_REPO by USERNAME (Hivy compliance)
  build_image $1 $2 $BATCAVE_REPO
  log "Done, application cell successfully synthetize !"

# )
