#!/usr/bin/with-contenv sh

if [ \( -n "$ENDPOINT" \) -a \( -n "$APIKEY" \) -a \( -e /supercronic/knot-cron \) ]; then
    exec s6-applyuidgid -u $SUID -g $SGID -G $SGID /supercronic/supercronic /supercronic/knot-cron
fi
