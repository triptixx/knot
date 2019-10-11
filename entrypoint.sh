#!/bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
CYANBOLD='\033[1;36m'
RESET='\033[0m'

CONFIG_DIR='/rundir;/storage;/config'

for FOLD in `echo $FOLDS | tr ';' '\n'`; do
    if su-exec $SUID:$SGID [ ! -w "$CONFIG_DIR" ]; then
        2>&1 echo -e "${RED}####################### WARNING #######################${RESET}"
        2>&1 echo
        2>&1 echo -e "${RED}     No permission to write in '$CONFIG_DIR' directory.${RESET}"
        2>&1 echo -e "${RED}       Correcting permissions to prevent a crash.${RESET}"
        2>&1 echo
        2>&1 echo -e "${RED}#######################################################${RESET}"
        2>&1 echo

        chown $SUID:$SGID "$CONFIG_DIR"
    fi
done
