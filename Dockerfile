ARG ALPINE_TAG=3.20
ARG KNOT_VER=3.3.8
ARG SUPERCRONIC_VER=0.2.30

FROM loxoo/alpine:${ALPINE_TAG} AS builder

ARG KNOT_VER
ARG SUPERCRONIC_VER

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
    make -j$(nproc); \
    make install DESTDIR=/output; \
    rm -rf /output/rundir/* /output/storage/* /output/config/*; \
    find /output -exec sh -c 'file "{}" | grep -q ELF && strip --strip-debug "{}"' \;

### install modules python
WORKDIR /output
RUN apk add py3-pip; \
    PY_VER=$(python -c "import sysconfig; print(sysconfig.get_path('purelib'))"); \
    pip install -t /output/${PY_VER} xmltodict

### install supercronic
WORKDIR /supercronic-src
RUN apk add --no-cache go upx; \
    git clone https://github.com/aptible/supercronic.git --branch v${SUPERCRONIC_VER} --depth 1 .; \
    go mod vendor; \
    go build -ldflags "-s -w" -o /output/supercronic/supercronic; \
    upx /output/supercronic/supercronic

COPY *.py /output/supercronic/
COPY *.sh /output/usr/local/bin/
RUN chmod +x /output/usr/local/bin/*.sh

#==============================================================

FROM loxoo/alpine:${ALPINE_TAG}

ARG KNOT_VER
ENV SUID=901 SGID=901

LABEL org.label-schema.name="knot" \
      org.label-schema.description="A Docker image for Knot authoritative-only DNS server" \
      org.label-schema.url="https://github.com/CZ-NIC/knot.git" \
      org.label-schema.version=${KNOT_VER}

COPY --from=builder /output/ /

RUN apk add --no-cache gnutls userspace-rcu protobuf-c fstrm lmdb libedit libidn2 nghttp2 python3 py3-requests; \
    adduser -D -u $SUID -s /sbin/nologin knot

VOLUME ["/rundir", "/storage", "/config"]

EXPOSE 53/TCP 53/UDP

HEALTHCHECK --start-period=10s --timeout=5s \
    CMD /knot/bin/kdig @127.0.0.1 -p 53 +short +time=1 +retry=0 localhost A

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/knot/sbin/knotd", "-c", "/config/knot.conf"]
