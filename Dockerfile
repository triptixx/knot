ARG KNOT_VER="2.8.4"

FROM loxoo/alpine:3.10 AS builder

ARG KNOT_VER

### install knot
WORKDIR /knot-src
RUN apk add --no-cache \
        build-base git autoconf automake \
        libtool gnutls-dev userspace-rcu-dev \
        protobuf-c-dev fstrm-dev libedit-dev libidn-dev; \
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
    find /output -exec sh -c 'file "{}" | grep -q ELF && strip --strip-debug "{}"' \;

### install modules perl
WORKDIR /output
RUN apk add --no-cache \
        perl-dev libressl libressl-dev zlib-dev; \
    perl -MCPAN -e "install XML::RPC"; \
    perl -MCPAN -e "install Net::DNS"; \
    cp -a --parents /usr/local/share/perl5/site_perl .

ADD entrypoint.sh /output/usr/local/bin/
RUN chmod +x /output/usr/local/bin/entrypoint.sh /output

#=============================================================

FROM loxoo/alpine:3.10

ARG KNOT_VER
ENV SUID=900 SGID=900

LABEL org.label-schema.name="knot" \
      org.label-schema.description="A Docker image for Knot authoritative-only DNS server" \
      org.label-schema.url="https://github.com/CZ-NIC/knot.git" \
      org.label-schema.version=${KNOT_VER}

COPY --from=builder /output/ /

RUN apk add --no-cache gnutls userspace-rcu protobuf-c fstrm-dev libedit libidn perl
