FROM        debian:buster
LABEL       maintainer="<contact@camptocamp.com>"

ENV         DEBIAN_FRONTEND=noninteractive \
            SERVER_KEY_SUBJECT="/C=CH/ST=Vaud/L=Lausanne/O=Camptocamp S.A./OU=BS/CN=pg/emailAddress=contact@camptocamp.com/" \
            PGBOUNCER_CONFIG=/etc/pgbouncer/pgbouncer.ini \
            PGBOUNCER_USER=postgres \
            PGBOUNCER_MD5SUM=7ab1cb972feda95afe4a9c6d9eb0734b


RUN         set -x \
            && apt-get -qq update \
            && apt-get install -yq --no-install-recommends openssl ca-certificates libevent-2.1-6 libpam0g libssl1.1 libc-ares2 libpq5 \
            && apt-get install  -yq --no-install-recommends wget build-essential libevent-dev libpam0g-dev libssl-dev libc-ares-dev libpq-dev pkg-config pandoc postgresql python3 debhelper dh-autoreconf \
            && wget https://github.com/pgbouncer/pgbouncer/releases/download/pgbouncer_1_12_0/pgbouncer-1.12.0.tar.gz \
            && md5sum pgbouncer-1.12.0.tar.gz | grep ${PGBOUNCER_MD5SUM} \
            && tar xf pgbouncer-1.12.0.tar.gz \
            && cd pgbouncer-1.12.0 \
            && ./autogen.sh && ./configure \
            && make \
            && make install \
            && apt-get remove --purge -y --auto-remove wget build-essential libevent-dev libpam0g-dev libssl-dev libc-ares-dev libpq-dev pkg-config pandoc postgresql python3 debhelper dh-autoreconf \
            && apt-get clean \
            && cd .. && rm -rf pgbouncer-1.12.0 pgbouncer-1.12.0.tar.gz

ADD         root/* ./
VOLUME      /opt/pgbouncer/ssl
EXPOSE      6432
ENTRYPOINT  ["./entrypoint.sh"]
