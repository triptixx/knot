#!/bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'

CONFIG_DIR='/rundir;/storage;/config'

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

exec su-exec $SUID:$SGID sh <<EOF

if [ ! \( -e /config/*.zone \) -o ! \( -e /config/knot.conf \) ]; then
    /usr/local/bin/gen-config.sh
fi

exec "$@"

EOF
