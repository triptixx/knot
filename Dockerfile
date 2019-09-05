FROM loxoo/alpine:latest

ENV PERL_MM_USE_DEFAULT=1 \
    PATH="/opt/knot/sbin:$PATH"

SHELL ["/bin/sh", "-exc"]

RUN apk upgrade --no-cache; \
    apk add --no-cache tzdata perl userspace-rcu gnutls libedit; \
    apk add --no-cache --virtual=.build-deps build-base perl-dev libressl libressl-dev libidn-dev zlib-dev git autoconf automake libtool gnutls-dev userspace-rcu-dev libedit-dev; \
    ### install perl
    perl -MCPAN -e "install XML::RPC"; \
    perl -MCPAN -e "install Net::DNS"; \
    ### install knot
    git clone "https://github.com/CZ-NIC/knot.git" -b master "/tmp/knot"; \
    cd "/tmp/knot"; \
    autoreconf -i -f; \
    ./configure --prefix=/opt/knot \
                --disable-static \
                --enable-fastparser \
                --disable-documentation \
                --without-module-dnsproxy \
                --without-module-noudp \
                --without-module-stats \
                --without-module-synthrecord \
                --without-module-whoami; \
    make -j$(nproc); \
    make install; \
    find "/opt/knot" -exec sh -c 'file "{}" | grep -q ELF && strip -s "{}"' \;; \
    ### install crontab
    echo -e "# do daily/weekly/monthly maintenance\n# min   hour    day     month   weekday command\n*/30    *       *       *       *       perl /opt/knot/gandi-publish-ds\n*/45    *       *       *       *       perl /opt/knot/gandi-remove-dead-keys" > "/etc/crontabs/knot"; \
    sed -i '/^#.*/!d' "/etc/crontabs/root"; \
    ###
    adduser -D -u 1000 -s /sbin/nologin knot; \
    apk del --no-cache .build-deps; \
    rm -rf "/var/lib/apk/"* "/var/cache/apk/"* "/var/tmp/"* "/tmp/"* "/root/".??* "/root/"*

COPY rootfs /
RUN chmod u+x "/usr/local/bin/entrypoint.sh"

ENTRYPOINT ["entrypoint.sh"]
CMD ["knotd"]
