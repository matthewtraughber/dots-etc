#!/usr/bin/env sh
#
### original sourced from https://gist.github.com/t413/3e616611299b22b17b08baa517d2d02c
#
## manage an OpenWRT LetsEncrypt https installation
# HOWTO:
# - put update.sh in its own directory (like /root/.https)
# - run ./update.sh your.domain.com (that domain needs to point to your router)
#  * this get an issued cert from letsencrypt.org using the webroot verification method
#  * also installs curl and ca-certificates packages
# - use crontab -e; add the line `0 0 * * * "/root/.https/update.sh" >>/root/.https/log.txt 2>&`
#  * this runs the update every day, logging everything to log.txt
#

THIS_FOLDER=$( cd "$( dirname "${BASH_SOURCE:-$0}" )" && pwd ) # get path of this script

log() { echo "[$(date)] $@"; }

log "starting $0 at in $THIS_FOLDER"

# UCI is this great utility for editing /etc/config/* files easily
if uci get firewall.http &> /dev/null; then
  ## first time running!
  log "adding http firewall rule"
  uci set firewall.http=rule
  uci set firewall.http.target=ACCEPT
  uci set firewall.http.src=wan
  uci set firewall.http.proto=tcp
  uci set firewall.http.dest_port=80
  uci set firewall.http.name='http web configuration'
fi

HTTP_LISTEN="$(uci get uhttpd.main.listen_http 2>/dev/null)" ##backup existing config
HTTP_ENABLED="$(uci get firewall.http.enabled 2>/dev/null)" ##backup existing config
[ ! -z $HTTP_LISTEN ] && [ "$HTTP_ENABLED" != "0" ] && RESTORE_HTTP=true || RESTORE_HTTP=false;
log "HTTP server previously *$RESTORE_HTTP*"

log "enabling http server"
#uci set firewall.http.enabled=1 # uci: Invalid argument
uci set uhttpd.main.listen_http=80
uci commit
/etc/init.d/firewall restart &> /dev/null
/etc/init.d/uhttpd restart &> /dev/null

if [ ! -f acme.sh ]; then
  log "downloading acme.sh from github"
  curl https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh > acme.sh || exit 2;
  chmod a+x "acme.sh"
fi

cd "$THIS_FOLDER"
if [ ! -z "$*" ]; then
  [ "$#" -gt 1 ] && { log "only works with 1 domain"; exit 3; }
  DOMAIN="$1"
  log "setting up domain $DOMAIN"
  if ./acme.sh --issue -d "$DOMAIN" -w /www; then
    KEYFILE="$THIS_FOLDER/$DOMAIN/$DOMAIN.key"
    [ -f "$KEYFILE" ] || { log "WARNING: key file missing"; }
    uci set uhttpd.main.key "$KEYFILE"
    uci set uhttpd.main.cert "$THIS_FOLDER/$DOMAIN/$DOMAIN.cert"
    uci commit uhttpd
    /etc/init.d/uhttpd restart &> /dev/null
    log "set uhttpd.main.key/cert to $(uci get uhttpd.main.key)/cert"
  else
    log "./acme.sh returned error for domain $DOMAIN"
  fi
else
  log "running acme.sh update"
  sleep 1
  ./acme.sh --cron #--force
fi

log "restoring port 80 http server configuration, enabled=$RESTORE_HTTP"
if [ $RESTORE_HTTP = true ]; then
  uci set uhttpd.main.listen_http="$HTTP_LISTEN"
  # uci set firewall.http.enabled=1 # uci: Invalid argument
else
  uci delete uhttpd.main.listen_http
  #uci set firewall.http.enabled=0 # uci: Invalid argument
fi
uci commit
/etc/init.d/firewall restart &> /dev/null
/etc/init.d/uhttpd restart &> /dev/null
[ $RESTORE_HTTP = true ] && log "http server staying enabled" || log "disabled HTTP server"

log "finished $0 at $(date)"
