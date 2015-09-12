#!/usr/bin/env bash
# From http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
#IFS=$'\n\t'
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
  local RESULT=$(wget -qO- http://${CONSUL_HOST}:${CONSUL_PORT}/v1/kv/$KEY | jq -r '.[0].Value' | base64 --decode)
  [ -n "$RESULT" ] || RESULT=$DEFAULT
  echo $RESULT
}

function build_image() {
  local path=$1; local commit=$2
  log "Building $path ... (commit $commit)"

  APP="$1"; IMAGE="$RECEIVE_USER/$APP"; CACHE_DIR="$BATCAVE_ROOT/$APP/cache"
  log "Streaming app into $RECEIVE_USER/$APP ..."
  id=$(cat | docker --host $DOCKER_HOST run -i -a stdin ${BATCAVE_BASE} /bin/bash -c "mkdir -p /app && tar -xC /app")
  test $(docker --host $DOCKER_HOST wait $id) -eq 0
  log "Commiting $id as $IMAGE"
  docker --host ${DOCKER_HOST} commit $id $IMAGE > /dev/null
  [[ -d $CACHE_DIR ]] || mkdir $CACHE_DIR

  log "Scheduling application build ..."
  batcave --username $RECEIVE_USER --app $APP --commit $commit
}

function clean_up() {
  # delete all non-running container
  docker --host $DOCKER_HOST ps -a | grep 'Exit' | awk '{print $1}' | xargs docker --host $DOCKER_HOST rm &> /dev/null &
  # delete unused images
  docker --host $DOCKER_HOST images | grep '<none>' | awk '{print $3}' | xargs docker --host $DOCKER_HOST rmi &> /dev/null &
  # delete deprecated images
  docker --host $DOCKER_HOST images | grep 'months' | awk '{print $3}' | xargs docker --host $DOCKER_HOST rmi &> /dev/null &
}

# Main (
  readonly PROJECT=$1
  readonly COMMIT=$2;

  # Specific behavior
  readonly LOG_PATH=${LOG_PATH:="/tmp"}
  readonly RECEIVE_USER=${RECEIVE_USER:="batcave"}
  readonly CONSUL_HOST=${CONSUL_HOST:="localhost"}
  readonly CONSUL_PORT=${CONSUL_PORT:="8500"}
  readonly BATCAVE_ROOT=${BATCAVE_ROOT:="/tmp/repos"}
  readonly BATCAVE_BASE=$(read_consul_parameter "batcave/$RECEIVE_USER/base" "hivetech/batcave:buildstep")
  readonly BATCAVE_REPO=$(read_consul_parameter "batcave/$RECEIVE_USER/docker/repo" "batcave")
  [ -d $BATCAVE_ROOT ] || mkdir $BATCAVE_ROOT
  [[ -f $BATCAVE_ROOT/batcaverc ]] && source $BATCAVE_ROOT/batcaverc

  # TODO Get real user name
  readonly DOCKER_HOST=$(read_consul_parameter "batcave/$RECEIVE_USER/docker/host" "unix:///var/run/docker.sock")
  # FIXME Not accessible in functions
  # alias docker="docker --host ${DOCKER_HOST}"

  log "[DEBUG] Using $BATCAVE_BASE as image foundation"
  log "[DEBUG] Setting $BATCAVE_ROOT as Batcave root directory"
  log "[DEBUG] Using $BATCAVE_REPO as docker image repository"
  log "[DEBUG] Talking to docker at $DOCKER_HOST"

  log "[INFO] Cleaning up containers ..."
  clean_up

  log "[DEBUG] Push User: $RECEIVE_USER"
  log "[DEBUG] Push Repo: $RECEIVE_REPO"
  build_image $PROJECT $COMMIT
  log "Done."

# )
