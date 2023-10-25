[hub]: https://hub.docker.com/r/loxoo/knot
[git]: https://github.com/triptixx/knot/tree/master
[actions]: https://github.com/triptixx/knot/actions/workflows/main.yml

# [loxoo/knot][hub]
[![Git Commit](https://img.shields.io/github/last-commit/triptixx/knot/master)][git]
[![Build Status](https://github.com/triptixx/knot/actions/workflows/main.yml/badge.svg?branch=master)][actions]
[![Latest Version](https://img.shields.io/docker/v/loxoo/knot/latest)][hub]
[![Size](https://img.shields.io/docker/image-size/loxoo/knot/latest)][hub]
[![Docker Stars](https://img.shields.io/docker/stars/loxoo/knot.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/loxoo/knot.svg)][hub]

## Usage

```shell
docker run -d \
    --name=srvknot \
    --restart=unless-stopped \
    --hostname=srvknot \
    -p 53:53 \
    -p 53:53/udp \
    -e DOMAIN=example.com \
    -e NS2=ns2.example.net \
    -v $PWD/config:/config \
    -v $PWD/storage:/storage \
    -v $PWD/rundir:/rundir \
    loxoo/knot
```
If you subscribe to the NameSilo registrar, you can use the $ENDPOINT and $APIKEY variables that will trigger a cron configuration to automate DNSSEC registration tasks :
```shell
docker run -d \
    --name=srvknot \
    --restart=unless-stopped \
    --hostname=srvknot \
    -p 53:53 \
    -p 53:53/udp \
    -e DOMAIN=example.com \
    -e NS2=ns2.example.net \
    -e ENDPOINT=https://www.namesilo.com/api/ \
    -e APIKEY=XXXXXXXX... \
    -v $PWD/config:/config \
    -v $PWD/storage:/storage \
    -v $PWD/rundir:/rundir \
    loxoo/knot
```

## Environment

- `$SUID`         - User ID to run as. _default: `901`_
- `$SGID`         - Group ID to run as. _default: `901`_
- `$DOMAIN`       - Domain master zone. _required_
- `$NS2`          - Fqdn name of slave server zone. _required_
- `$MX`           - Name of mail server. _optional_
- `$CNAME`        - Name of different subdomain. Separated by commas. _optional_
- `$ENDPOINT`     - Name server of NameSilo API. _optional_
- `$APIKEY`       - Authentication NameSilo API Key. _optional_
- `$LOG_LEVEL`    - Logging severity levels. _default: `info`_
- `$TZ`           - Timezone. _optional_

## Volume

- `/rundir`       - A path for storing run-time data.
- `/storage`      - A data directory for storing zone files, journal database, and timers database.
- `/config`       - Server configuration file location.

## Network

- `53/udp`        - Dns port udp.
- `53/tcp`        - Dns port tcp.
