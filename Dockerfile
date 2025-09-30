FROM debian:stable-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential autoconf automake libtool pkg-config \
    libevent-dev libssl-dev libpam0g-dev libldap2-dev \
    ca-certificates wget git-core python3 pandoc \
 && rm -rf /var/lib/apt/lists/*

# Copier le code source (attend que tu mettes le repo dans le contexte docker)
# -> tu peux utiliser ADD/COPY d'un tarball ou d'un dossier local cloné; pas besoin de git dans l'image finale
WORKDIR /usr/src/
RUN git clone --recursive --branch pgbouncer_1_24_1 https://github.com/pgbouncer/pgbouncer.git
WORKDIR /usr/src/pgbouncer

RUN ./autogen.sh \
 && ./configure --prefix=/usr/local \
 && make -j$(nproc) \
 && make install

### Stage 1: final image (Debian slim minimal runtime)
FROM debian:stable-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libevent-2.1-7t64 \
 && rm -rf /var/lib/apt/lists/*

# create a non-root user and group
RUN groupadd -r pgbouncer && useradd -r -g pgbouncer -d /var/lib/pgbouncer -s /sbin/nologin pgbouncer \
 && mkdir -p /var/lib/pgbouncer /var/log/pgbouncer /etc/pgbouncer \
 && chown -R pgbouncer:pgbouncer /var/lib/pgbouncer /var/log/pgbouncer /etc/pgbouncer

# copy installed files from builder
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/etc/ /usr/local/etc/

# Symlink/move config files to /etc/pgbouncer to make it easy to mount ConfigMap there
# If pgbouncer installs defaults into /usr/local/etc, copy them:
RUN if [ -d /usr/local/etc/pgbouncer ]; then cp -r /usr/local/etc/pgbouncer/* /etc/pgbouncer/ || true; fi \
 && chown -R pgbouncer:pgbouncer /etc/pgbouncer

EXPOSE 6432

USER pgbouncer

ENTRYPOINT ["/usr/local/bin/pgbouncer"]

#
#WORKDIR /var/lib/pgbouncer
#
#RUN         set -x \
#            && apt-get -qq update \
#            && apt-get install -yq --no-install-recommends openssl ca-certificates libevent-2.1-6 libpam0g libssl1.1 libc-ares2 libpq5 \
#            && apt-get install  -yq --no-install-recommends wget build-essential libevent-dev libpam0g-dev libssl-dev libc-ares-dev libpq-dev pkg-config pandoc postgresql python3 debhelper dh-autoreconf \
#            && wget https://github.com/pgbouncer/pgbouncer/releases/download/pgbouncer_1_12_0/pgbouncer-1.12.0.tar.gz \
#            && md5sum pgbouncer-1.12.0.tar.gz | grep ${PGBOUNCER_MD5SUM} \
#            && tar xf pgbouncer-1.12.0.tar.gz \
#            && cd pgbouncer-1.12.0 \
#            && ./autogen.sh && ./configure \
#            && make \
#            && make install \
#            && apt-get remove --purge -y --auto-remove wget build-essential libevent-dev libpam0g-dev libssl-dev libc-ares-dev libpq-dev pkg-config pandoc postgresql python3 debhelper dh-autoreconf \
#            && apt-get clean \
#            && cd .. && rm -rf pgbouncer-1.12.0 pgbouncer-1.12.0.tar.gz
#
#ADD         root/* ./
#VOLUME      /opt/pgbouncer/ssl
#EXPOSE      6432
#ENTRYPOINT  ["./entrypoint.sh"]
