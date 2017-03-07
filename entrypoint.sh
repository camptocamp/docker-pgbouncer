#!/bin/bash
set -e

PG_LOG=/var/log/postgresql/
PG_CONFIG=/etc/pgbouncer/pgbouncer.ini
PG_USER=postgres

mkdir -p ${PG_LOG}
chmod -R 755 ${PG_LOG}
chown -R ${PG_USER}:${PG_USER} ${PG_LOG}

if test -n "${PG_HBA}"; then
  echo "${PG_HBA}" > /etc/pgbouncer/pg_hba.conf
fi

if test -n "${USERLIST}"; then
  echo "${USERLIST}" > /etc/pgbouncer/userlist.txt
fi

echo "Starting pgbouncer..."
exec pgbouncer -vvvv -u ${PG_USER} $PG_CONFIG
