ARG ALPINE_TAG=3.12
ARG KNOT_VER=3.0.3

FROM loxoo/alpine:${ALPINE_TAG} AS builder

ARG KNOT_VER
ARG PERL_MM_USE_DEFAULT=1
ARG GOPATH=/supercronic-src

### install knot
WORKDIR /knot-src
RUN apk add --no-cache build-base git autoconf automake libtool gnutls-dev userspace-rcu-dev \
                       protobuf-c-dev fstrm-dev lmdb-dev libedit-dev libidn2-dev nghttp2-dev linux-headers; \
    git clone https://gitlab.labs.nic.cz/knot/knot-dns --branch v${KNOT_VER} --depth 1 .; \
    autoreconf -sif; \
    ./configure --prefix=/knot \
                --with-rundir=/rundir \
                --with-storage=/storage \
                --with-configdir=/config \
                --with-module-dnstap=yes \
                --disable-fastparser \
                --disable-static \
                --disable-documentation; \
    make; \
    make install DESTDIR=/output; \
    rm -rf /output/rundir/* /output/storage/* /output/config/*; \
    find /output -exec sh -c 'file "{}" | grep -q ELF && strip --strip-debug "{}"' \;

### install modules perl
WORKDIR /output
RUN apk add --no-cache perl-dev openssl openssl-dev zlib-dev; \
    perl -MCPAN -e "install XML::RPC"; \
    perl -MCPAN -e "install Net::DNS"; \
    cp -a --parents /usr/local/*/*/site_perl .

### install supercronic
WORKDIR /supercronic-src
RUN apk add --no-cache go upx; \
    go get -d -u github.com/golang/dep; \
    cd ${GOPATH}/src/github.com/golang/dep; \
    DEP_LATEST=$(git describe --abbrev=0 --tags); \
    git checkout $DEP_LATEST; \
    go build -o ${GOPATH}/dep -ldflags="-X main.version=$DEP_LATEST" ./cmd/dep; \
    go get -d -u github.com/aptible/supercronic; \
    cd ${GOPATH}/src/github.com/aptible/supercronic; \
    ${GOPATH}/dep init; \
    ${GOPATH}/dep ensure -vendor-only; \
    go build -ldflags "-s -w" -o /output/supercronic/supercronic; \
    upx /output/supercronic/supercronic

COPY *.pl /output/supercronic/
COPY *.sh /output/usr/local/bin/
RUN chmod +x /output/usr/local/bin/*.sh

#=============================================================

FROM loxoo/alpine:${ALPINE_TAG}

ARG KNOT_VER
ENV SUID=901 SGID=901

LABEL org.label-schema.name="knot" \
      org.label-schema.description="A Docker image for Knot authoritative-only DNS server" \
      org.label-schema.url="https://github.com/CZ-NIC/knot.git" \
      org.label-schema.version=${KNOT_VER}

COPY --from=builder /output/ /

RUN apk add --no-cache gnutls userspace-rcu protobuf-c fstrm lmdb libedit libidn2 nghttp2 perl libressl; \
    adduser -D -u $SUID -s /sbin/nologin knot

VOLUME ["/rundir", "/storage", "/config"]

EXPOSE 53/TCP 53/UDP

HEALTHCHECK --start-period=10s --timeout=5s \
    CMD /knot/bin/kdig @127.0.0.1 -p 53 +short +time=1 +retry=0 localhost A

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/knot/sbin/knotd", "-c", "/config/knot.conf"]
