#!/bin/bash
set -e

# TODO Merge it in common.sh or whatever
ci_file=$1
app_root=/app
app_name=app

function log() {
  TIME=`date +"%T"`
  printf " -----> $@\n"
  printf "[ $TIME ] -----> $@\n" >> /var/log/batcave.log
}

function load_yaml_property() {
  property=$(ruby -e "require 'yaml';puts YAML.load_file('$ci_file')['$1']")
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
    cp $app_root/$line /etc/service/$script_name/run
  done <<< "$1"
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
    -d '{"message": "Successfully synthetize application ${app_name}", "color": "green"}'
 }

# TODO env property
printf "Parsing $ci_file ...\n"
language=$(load_yaml_property "language")
before_install=$(load_yaml_property "before_install")
install=$(load_yaml_property "install")
before_script=$(load_yaml_property "before_script")
script=$(load_yaml_property "script")
after_success=$(load_yaml_property "after_success")
app_command=$(load_yaml_property "command")
workers=$(load_yaml_property "workers")
notifications=$(load_yaml_property "notifications")

cd $app_root
process "$before_install"
process "$install"
process "$before_script"
process "$script"
[ -n "$workers" ] && add_runit_entries "$workers"
[ $? -eq 0 ] && process "$after_success"

# TODO Procfile, runit, and notifcations could be common ways to start the
#      container (i.e. merge this section with buildpack builder)

# Runit process
mkdir -p /etc/service/${app_name}
cat > /etc/service/${app_name}/run <<EOF
#!/bin/bash
set -e
cd $app_root
$app_command >> /var/log/${app_name}.log 2>&1
EOF
chmod +x /etc/service/${app_name}/run

# TODO Read $notification to choose notification system
# TODO Read email, room_id and api_token from $notification
#send_hipchat_notification "xavier.bruhiere@gmail.com" "Room_id" "api_key16156165151"
# TODO Mail notifications
# TODO Pushbullet notifications
log "Done."
