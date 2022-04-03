#!/command/with-contenv /bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'

CONFIG_DIR='/rundir;/storage;/config;/supercronic'

for DIR in `echo $CONFIG_DIR | tr ';' '\n'`; do
    if s6-applyuidgid -u $SUID -g $SGID -G $SGID [ ! -w "$DIR" ]; then
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

s6-applyuidgid -u $SUID -g $SGID -G $SGID sh <<EOF
    source /usr/local/bin/gen-config.sh
EOF
