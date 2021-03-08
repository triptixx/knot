#!/bin/sh
#set -eo pipefail
set -xv

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'

CONFIG_DIR='/rundir;/storage;/config;/supercronic'

for DIR in `echo $CONFIG_DIR | tr ';' '\n'`; do
    if su-exec $SUID:$SGID [ ! -w "$DIR" ]; then
        2>&1 echo -e "${RED}####################### WARNING #######################${RESET}"
        2>&1 echo
        2>&1 echo -e "${RED}     No permission to write in '$DIR' directory.${RESET}"
        2>&1 echo -e "${RED}       Correcting permissions to prevent a crash.${RESET}"
        2>&1 echo
        2>&1 echo -e "${RED}#######################################################${RESET}"
        2>&1 echo

        chown $SUID:$SGID "$DIR"
    fi
done

su-exec $SUID:$SGID sh <<EOF

source /usr/local/bin/gen-config.sh

if [ \( -n "$ENDPOINT" \) -a \( -n "$APIKEY" \) -a \( -e /supercronic/knot-cron \) ]; then
    /supercronic/supercronic /supercronic/knot-cron &
fi

EOF

exec "$@"
