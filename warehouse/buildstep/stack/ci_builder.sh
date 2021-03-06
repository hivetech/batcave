#!/bin/bash
set -e

# TODO Merge it in common.sh or whatever
readonly CI_FILE=$1
readonly APP_ROOT=/app
readonly APP_NAME=app
readonly CONSUL_CONFIG_DIR=/etc/consul.d

function log() {
  TIME=`date +"%T"`
  printf " -----> $@\n"
  printf "[ $TIME ] -----> $@\n" >> /var/log/batcave.log
}

function load_yaml_property() {
  property=$(ruby -e "require 'yaml';puts YAML.load_file('$CI_FILE')['$1']")
  echo "$property"
}

function process() {
  while read -r line; do
    log "[ RUN ] $line"
    eval $line
  done <<< "$1"
}

function add_runit_entries() {
  while read -r line; do
    log "[ ADD ] $line"
    runit_script=$(basename $line)
    script_name=$(echo $runit_script | sed 's/-\([^ ]$\)/\1/p')

    mkdir /etc/service/$script_name
    cp $APP_ROOT/$line /etc/service/$script_name/run
  done <<< "$1"
}

function setup_consul_config() {
  local readonly CONFIG_DIR=$1
  log "[ ADD ] New consul services and checks : $(ls $CONFIG_DIR)"
  mv $CONFIG_DIR/*.json $CONSUL_CONFIG_DIR
}

# https://www.hipchat.com/docs/apiv2/method/send_room_notification
function send_hipchat_notification() {
  # TODO Test Access (see doc)
  # TODO Custom color for build status
  local readonly EMAIL=$1
  local readonly ROOM_ID=$2
  local readonly API_TOKEN=$3
  local readonly API_URL="https://api.hipchat.com"
  local readonly ENDPOINT="v2/room/$ROOM_ID/notification?auth_token=$API_TOKEN"

  log "Notifying $EMAIL ..."
  curl -X POST -H "content-type:application/json" "$API_URL/$ENDPOINT" \
    -d '{"message": "Successfully synthetize application ${APP_NAME}", "color": "green"}'
 }

# TODO env property
printf "Parsing $CI_FILE ...\n"
language=$(load_yaml_property "language")
before_install=$(load_yaml_property "before_install")
install=$(load_yaml_property "install")
before_script=$(load_yaml_property "before_script")
script=$(load_yaml_property "script")
after_success=$(load_yaml_property "after_success")
app_command=$(load_yaml_property "command")
workers=$(load_yaml_property "workers")
notifications=$(load_yaml_property "notifications")

cd $APP_ROOT
[ -n "$before_install" ] && process "$before_install"
[ -n "$install" ] && process "$install"
[ -n "$before_script" ] && process "$before_script"
[ -n "$script" ] && process "$script"
[ -n "$workers" ] && add_runit_entries "$workers"
[ -d "build/consul" ] && setup_consul_config "build/consul"
[ $? -eq 0 ] && process "$after_success"

# TODO Procfile, runit, and notifcations could be common ways to start the
#      container (i.e. merge this section with buildpack builder)

# Runit process
mkdir -p /etc/service/${APP_NAME}
cat > /etc/service/${APP_NAME}/run <<EOF
#!/bin/bash
set -e
cd $APP_ROOT
$app_command >> /var/log/${APP_NAME}.log 2>&1
EOF
chmod +x /etc/service/${APP_NAME}/run

# TODO Read $notification to choose notification system
# TODO Read email, room_id and api_token from $notification
#send_hipchat_notification "xavier.bruhiere@gmail.com" "Room_id" "api_key16156165151"
# TODO Mail notifications
# TODO Pushbullet notifications
log "Done."
