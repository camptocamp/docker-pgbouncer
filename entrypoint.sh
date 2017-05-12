#!/bin/bash
set -e

PG_CONFIG=/etc/pgbouncer/pgbouncer.ini
PG_USER=postgres

# Generate key and certificate for ssl connection
if [ ! -r /etc/pgbouncer/ssl/server.key ]; then
	echo "Generating new key and certificate for SSL connection"
	CWD=`pwd`
	cd /etc/pgbouncer/ssl/
	openssl genrsa -des3 -passout pass:xxxx -out server.pass.key 2048
	openssl rsa -passin pass:xxxx -in server.pass.key -out server.key
	rm -f server.pass.key
	openssl req -new -key server.key -out server.csr -subj "${CERTIFICATE_DESCRIPTION}"
	openssl x509 -req -in server.csr -signkey server.key -out server.crt
	rm -f server.csr
	chown -R ${PG_USER}:${PG_USER} /etc/pgbouncer/ssl/
	cd "$CWD"
fi

if test -n "${PG_HBA}"; then
  echo "${PG_HBA}" > /etc/pgbouncer/pg_hba.conf
fi

if test -n "${USERLIST}"; then
  echo "${USERLIST}" > /etc/pgbouncer/userlist.txt
fi

if test -n "${DB_MAPPING}"; then
	cat /etc/pgbouncer/pgbouncer.ini.template1 > /etc/pgbouncer/pgbouncer.ini
	echo "${DB_MAPPING}" >> /etc/pgbouncer/pgbouncer.ini
	cat /etc/pgbouncer/pgbouncer.ini.template2 >> /etc/pgbouncer/pgbouncer.ini
fi

if test -n "${EXTRA_CONFIG}"; then
	echo "${EXTRA_CONFIG}" >> /etc/pgbouncer/pgbouncer.ini
fi

echo "Starting pgbouncer..."
exec pgbouncer -v -u ${PG_USER} $PG_CONFIG
