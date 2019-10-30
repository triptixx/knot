#!/bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'
error() { >&2 echo -e "${RED}Error: $@${RESET}"; exit 1; }

if [ ! \( -e /config/*.zone \) -o ! \( -e /config/knot.conf \) ]; then

    if [ \( -z "$DOMAIN" \) -o \( -z "$NS2" \) ]; then
        error "Missing 'DOMAIN' or 'NS2' arguments required for auto configuration"
    fi

    if [ ! -e /config/knot.conf ]; then

        >&2 echo 'Auto generate knot config file'

        IPNS2="$(/knot/bin/kdig ${NS2} +short)"
        if [ -z "$IPNS2" ]; then
            error "Missing 'IPNS2', Impossible to resolve ip of ${NS2}"
        fi

        cat > /config/knot.conf <<EOL
server:
    identity:
    version:
    nsid:
    user: knot:knot
    listen: 0.0.0.0@53

remote:
  - id: slave
    address: ${IPNS2}@53

acl:
  - id: acl_slave
    address: ${IPNS2}
    action: transfer

submission:
  - id: sub_ksk
    parent: slave

policy:
  - id: rsa
    algorithm: RSASHA256
    ksk-size: 2048
    zsk-size: 1024
    zsk-lifetime: 90d
    ksk-lifetime: 365d
    nsec3: on
    ksk-submission: sub_ksk

mod-rrl:
  - id: default
    rate-limit: 200
    slip: 2

template:
  - id: default
    global-module: mod-rrl/default

zone:
  - domain: ${DOMAIN}
    file: /config/${DOMAIN}.zone
    notify: slave
    acl: acl_slave
    semantic-checks: on
    disable-any: on
    dnssec-signing: on
    dnssec-policy: rsa
    zonefile-load: difference

log:
  - target: stdout
    any: ${LOG_LEVEL:-info}
EOL

    fi

    if [ ! -e /config/*.zone ]; then

        >&2 echo 'Auto generate dns zone file'

        SERIAL="$(date +"%Y%m%d%S")"
        NS1="ns1.${DOMAIN}"
        IPNS1="$(wget -qO- icanhazip.com)"
        NSMAIL="${MX%%.*}.${DOMAIN}"

        ###### start SOA ######
        TXTZONE="\$ORIGIN ${DOMAIN}.\n"
        TXTZONE="${TXTZONE}\$TTL 7200\n\n"
        TXTZONE="${TXTZONE}@ IN SOA ${NS1}. hostmaster.${DOMAIN}. (\n"
        TXTZONE="${TXTZONE}${SERIAL} ; Serial\n"
        TXTZONE="${TXTZONE}14400 ; Refresh - 4 hour\n"
        TXTZONE="${TXTZONE}3600 ; Retry - 1 hour\n"
        TXTZONE="${TXTZONE}1209600 ; Expire - 2 week\n"
        TXTZONE="${TXTZONE}10800 ) ; Minimum - 3 hour\n\n"

        ###### start NAMESERVERS #######
        TXTZONE="${TXTZONE}; NAMESERVERS\n"
        TXTZONE="${TXTZONE}@ IN NS ${NS1}.\n"
        TXTZONE="${TXTZONE}@ IN NS ${NS2}.\n\n"

        ###### start CAA #######
        TXTZONE="${TXTZONE}; Enregistrement CAA (Certificat)\n"
        TXTZONE="${TXTZONE}@ IN CAA 0 issue \"letsencrypt.org\"\n\n"

        ###### start TXT #######
        TXTZONE="${TXTZONE}; Enregistrements TXT\n"
        TXTZONE="${TXTZONE}@ IN TXT \"v=spf1 ip4:${IPNS1} -all\"\n\n"

        ###### start MX #######
        if [ -n "$MX" ]; then
            TXTZONE="${TXTZONE}; Enregistrement MX (Mail Exchanger)\n"
            TXTZONE="${TXTZONE}@ IN MX 10 ${NSMAIL}.\n\n"
        fi

        ###### start A #######
        TXTZONE="${TXTZONE}; Enregistrements A\n"
        TXTZONE="${TXTZONE}@ IN A ${IPNS1}\n"
        TXTZONE="${TXTZONE}ns1 IN A ${IPNS1}"
        if [ -n "$MX" ]; then
            TXTZONE="${TXTZONE}\n${MX%%.*} IN A ${IPNS1}"
        fi

        ###### start CNAME #######
        if [ -n "$CNAME" ]; then
            TXTZONE="${TXTZONE}\n\n; Enregistrements CNAME"
            while read -r name; do
                TXTZONE="${TXTZONE}\n${name%%.*} IN CNAME @"
            done << EOA
$(echo "$CNAME" | tr ',' '\n')
EOA
        fi

        echo -e "$TXTZONE" > "/config/${DOMAIN}.zone"

    fi
elif [ -e /config/knot.conf ]; then
    awk '/:$/ { flag="" } /log:/ { flag=1 } flag && NF && /any:/ { match($0,/^[[:space:]]+/); \
val=substr($0,RSTART,RLENGTH); $NF="'${LOG_LEVEL:-info}'"; print val $0; next } 1' /config/knot.conf
fi

if [ \( -n "$ENDPOINT" \) -a \( -n "$APIKEY" \) ]; then
    echo -e '*/10 * * * * perl /supercronic/gandi-publish-ds.pl\n
*/15 * * * * perl /supercronic/gandi-remove-dead-keys.pl' > /supercronic/knot-cron
fi
