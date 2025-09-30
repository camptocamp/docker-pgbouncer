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
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends libevent-2.1-7t64 \
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
