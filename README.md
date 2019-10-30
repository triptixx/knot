[hub]: https://hub.docker.com/r/loxoo/knot-s6
[mbdg]: https://microbadger.com/images/loxoo/knot-s6
[git]: https://github.com/triptixx/knot/tree/knot-s6
[actions]: https://github.com/triptixx/knot/actions

# [loxoo/knot-s6][hub]
[![Layers](https://images.microbadger.com/badges/image/loxoo/knot-s6.svg)][mbdg]
[![Latest Version](https://images.microbadger.com/badges/version/loxoo/knot-s6.svg)][hub]
[![Git Commit](https://images.microbadger.com/badges/commit/loxoo/knot-s6.svg)][git]
[![Docker Stars](https://img.shields.io/docker/stars/loxoo/knot-s6.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/loxoo/knot-s6.svg)][hub]
[![Build Status](https://github.com/triptixx/knot/workflows/docker%20build/badge.svg?branch=knot-s6)][actions]

## Usage

```shell
docker run -d \
    --name=srvknot \
    --restart=unless-stopped \
    --hostname=srvknot \
    -p 53:53 \
    -p 53:53/udp \
    -e DOMAIN=example.com \
    -e NS2=ns2.gandi.net \
    -v $PWD/config:/config \
    -v $PWD/storage:/storage \
    -v $PWD/rundir:/rundir \
    loxoo/knot-s6
```
If you subscribe to the Gandi registrar, you can use the $ENDPOINT and $APIKEY variables that will trigger a cron configuration to automate DNSSEC registration tasks :
```shell
docker run -d \
    --name=srvknot \
    --restart=unless-stopped \
    --hostname=srvknot \
    -p 53:53 \
    -p 53:53/udp \
    -e DOMAIN=example.com \
    -e NS2=ns2.gandi.net \
    -e ENDPOINT=https://rpc.gandi.net/xmlrpc/ \
    -e APIKEY=XXXXXXXX... \
    -v $PWD/config:/config \
    -v $PWD/storage:/storage \
    -v $PWD/rundir:/rundir \
    loxoo/knot-s6
```

## Environment

- `$SUID`         - User ID to run as. _default: `901`_
- `$SGID`         - Group ID to run as. _default: `901`_
- `$DOMAIN`       - Domain master zone. _required_
- `$NS2`          - Fqdn name of slave server zone. _required_
- `$MX`           - Name of mail server. _optional_
- `$CNAME`        - Name of different subdomain. Separated by commas. _optional_
- `$ENDPOINT`     - Name server of Gandi API. _optional_
- `$APIKEY`       - Authentication Gandi API Key. _optional_
- `$LOG_LEVEL`    - Logging severity levels. _default: `info`_
- `$TZ`           - Timezone. _optional_

## Volume

- `/rundir`       - A path for storing run-time data.
- `/storage`      - A data directory for storing zone files, journal database, and timers database.
- `/config`       - Server configuration file location.

## Network

- `53/udp`        - Dns port udp.
- `53/tcp`        - Dns port tcp.
