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

### [Usage]

### [Environment]

- `$SUID`                 - User ID to run as. _default: `900`_
- `$SGID`                 - Group ID to run as. _default: `900`_
- `$DOMAIN`               - Domain master zone. _required_
- `$NS2`                  - Fqdn name of slave server zone. _required_
- `$MX`                   - Name of mail server. _optional_
- `$CNAME`                - Name of different subdomain. _optional_
- `ENDPOINT`              - Name server of Gandi API. _optional_
- `APIKEY`                - Authentication Gandi API Key. _optional_
- `$LOG_LEVEL`            - Logging severity levels. _default: `info`_
- `$TZ`                   - Timezone. _optional_
