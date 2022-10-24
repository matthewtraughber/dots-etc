#!/usr/bin/env sh
#
### original sourced from https://gist.github.com/t413/3e616611299b22b17b08baa517d2d02c
#
## manage an OpenWRT LetsEncrypt https installation
# HOWTO:
# - put openWRT-letsEncrypt.sh in its own directory (like /root/.https)
# - run ./openWRT-letsEncrypt.sh your.domain.com stage|prod (that domain needs to point to your router, LetsEncrypt stage or prod servers)
#  * this get an issued cert from letsencrypt.org using the standalone tls method
# - use crontab -e; add the line '0 0 * * * /root/.https/openWRT-letsEncrypt.sh DOMAIN STAGE|PROD >> /root/.https/openWRT-letsEncrypt.log'
#  * this runs the update every day, logging everything to openWRT-letsEncrypt.log
#

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE:-$0}" )" && pwd ) # get path of this script
ROOT_DIR=$(dirname "$( cd "$( dirname "${BASH_SOURCE:}" )" && pwd )") # get root directory of workspace

log() { echo "[$(date)] $@"; }
log "starting $0 at in $SCRIPT_DIR"

# open port for HTTPS validation
uci add firewall redirect
uci set firewall.@redirect[-1].target=DNAT
uci set firewall.@redirect[-1].src=wan
uci set firewall.@redirect[-1].proto=tcp
uci set firewall.@redirect[-1].src_dport=443
uci set firewall.@redirect[-1].dest=lan
uci set firewall.@redirect[-1].dest_ip=10.0.0.1
uci set firewall.@redirect[-1].dest_port=8443

# commit changes
uci commit firewall

# restart firewall
/etc/init.d/firewall restart &> /dev/null

if [ ! -f acme.sh ]; then # TODO: does this get the newest version of acme.sh?
  log "downloading acme.sh from github"
  curl https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh > $SCRIPT_DIR/acme.sh || exit 2;
  chmod a+x $SCRIPT_DIR/acme.sh
fi

# start werk
if [ ! -z "$*" ]; then
  # check if too many parameters were passed
  [ "$#" -gt 2 ] && { log "too many parameters"; exit 3; }

  DOMAIN="$1" # set domain to parameter
  log "setting up domain $DOMAIN"

  if [ $# -eq 2 ] ; then
    ENV="$2" # set env to parameter
    log "env flag is set to $ENV"

    if [ $ENV == "stage" ] ; then
      ACME="$SCRIPT_DIR/acme.sh -d "$DOMAIN" --issue --tls --tlsport 8443 --staging --force"
    elif [ $ENV == "prod" ] ; then
      ACME="$SCRIPT_DIR/acme.sh -d "$DOMAIN" --issue --tls --tlsport 8443"
    else
      log "invalid parameter - please specify stage or prod"
      exit 3
    fi
  else
    log "env flag isn't set; using stage"
    ACME="$SCRIPT_DIR/acme.sh -d "$DOMAIN" --issue --tls --tlsport 8443 --staging"
  fi

  # do werk
  if $ACME ; then
    # grab key & cert files
    KEYFILE="$ROOT_DIR/.acme.sh/$DOMAIN/$DOMAIN.key"
    CERTFILE="$ROOT_DIR/.acme.sh/$DOMAIN/$DOMAIN.cer"

    # log potential problems
    [ -f "$KEYFILE" ] || { log "WARNING: key file missing"; }
    [ -f "$CERTFILE" ] || { log "WARNING: cer file missing"; }

    # set new key & cert files
    uci set uhttpd.main.key=$KEYFILE
    uci set uhttpd.main.cert=$CERTFILE

    # commit changes
    uci commit uhttpd

    # restart uhttpd
    /etc/init.d/uhttpd restart &> /dev/null

    log "set uhttpd.main.key/cert to $KEYFILE & $CERTFILE"
  else
    log "./acme.sh returned error for $DOMAIN"
  fi
else
  # TODO: does this --cron work?
  log "running acme.sh update"
  sleep 1
  ./acme.sh --cron #--force
fi

log "cleaning up firewall modifications"
# firewall cleanup
uci delete firewall.@redirect[-1]

# commit cleanup
uci commit firewall

# restart firewall
/etc/init.d/firewall restart &> /dev/null

log "finished $0 at $(date)"
log " "
log " "
