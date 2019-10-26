[hub]: https://hub.docker.com/r/loxoo/knot
[mbdg]: https://microbadger.com/images/loxoo/knot
[git]: https://github.com/triptixx/knot
[actions]: https://github.com/triptixx/knot/actions

# [loxoo/knot][hub]
[![Layers](https://images.microbadger.com/badges/image/loxoo/knot.svg)][mbdg]
[![Latest Version](https://images.microbadger.com/badges/version/loxoo/knot.svg)][hub]
[![Git Commit](https://images.microbadger.com/badges/commit/loxoo/knot.svg)][git]
[![Docker Stars](https://img.shields.io/docker/stars/loxoo/knot.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/loxoo/knot.svg)][hub]
[![Build Status](https://github.com/triptixx/knot/workflows/docker%20build/badge.svg)][actions]

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
    -v /config:/config \
    -v /storage:/storage \
    -v /rundir:/rundir \
    loxoo/knot
```

Si vous êtes abonné au registrar Gandi, vous pouvez utiliser les variables $ENDPOINT et $APIKEY qui déclencheront une configuration cron pour automatiser les taches d'enregistrement DNSSEC :
```shell
docker run -d \
    --name=srvknot \
    --restart=unless-stopped \
    --hostname=srvknot \
    -p 53:53 \
    -p 53:53/udp \
    -e DOMAIN=example.com \
    -e NS2=ns2.gandi.net \
    -v /config:/config \
    -v /storage:/storage \
    -v /rundir:/rundir \
    loxoo/knot
```

## Environment

- `$SUID`         - User ID to run as. _default: `900`_
- `$SGID`         - Group ID to run as. _default: `900`_
- `$DOMAIN`       - Domain master zone. _required_
- `$NS2`          - Fqdn name of slave server zone. _required_
- `$MX`           - Name of mail server. _optional_
- `$CNAME`        - Name of different subdomain. _optional_
- `$ENDPOINT`      - Name server of Gandi API. _optional_
- `$APIKEY`        - Authentication Gandi API Key. _optional_
- `$LOG_LEVEL`    - Logging severity levels. _default: `info`_
- `$TZ`           - Timezone. _optional_

## Volume

- `/rundir`       - A path for storing run-time data.
- `/storage`      - A data directory for storing zone files, journal database, and timers database.
- `/config`       - Server configuration file location

## Network

- `53/udp`        - Dns port udp.
- `53/tcp`        - Dns port tcp.
