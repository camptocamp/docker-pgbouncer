#!/bin/bash
set -e

mkdir -p /etc/pgbouncer/ssl

if [ -n "${CA_KEY}" ]
then
    echo "${CA_KEY}" > /etc/pgbouncer/ssl/root.key
else
    if [ -r "${CA_KEY_FILENAME}" ]
    then
       cp "${CA_KEY_FILENAME}" /etc/pgbouncer/ssl/root.key
    else
        echo "You must provide the CA Certificate and CA root key as environment variable. Check README.md"
        exit 1
    fi
fi

if [ -n "${CA_CERT}" ]
then
    echo "${CA_CERT}" > /etc/pgbouncer/ssl/root.crt
else
    if [ -r "${CA_CERT_FILENAME}" ]
    then
        cp "${CA_CERT_FILENAME}" /etc/pgbouncer/ssl/root.crt
    else
        echo "You must provide the CA Certificate and CA root key as environment variable. Check README.md"
        exit 1
    fi
fi

if [ ! \( -r /opt/pgbouncer/ssl/server.key -a  -r /opt/pgbouncer/ssl/server.crt \) ]
then
    echo "Generating new server key for " ${SERVER_KEY_SUBJECT}
    openssl req -new -nodes -text -out /opt/pgbouncer/ssl/server.csr -keyout /opt/pgbouncer/ssl/server.key -subj "${SERVER_KEY_SUBJECT}"
    echo "Signing key with root certificate"
    ls -l /opt/pgbouncer/ssl/server.csr
    ls -l /opt/pgbouncer/ssl/server.key
    ls -l /etc/pgbouncer/ssl/root.crt
    ls -l /etc/pgbouncer/ssl/root.key
    cat /etc/pgbouncer/ssl/root.crt
    openssl x509 -req -in /opt/pgbouncer/ssl/server.csr -text -days 365 -CA /etc/pgbouncer/ssl/root.crt -CAkey /etc/pgbouncer/ssl/root.key -CAcreateserial -out /opt/pgbouncer/ssl/server.crt
fi
cp /opt/pgbouncer/ssl/server.key /opt/pgbouncer/ssl/server.crt /etc/pgbouncer/ssl/
chmod 600 /etc/pgbouncer/ssl/root.crt /etc/pgbouncer/ssl/root.key
chmod 600 /etc/pgbouncer/ssl/server.key /etc/pgbouncer/ssl/server.crt


chown ${PGBOUNCER_USER} /etc/pgbouncer/ssl/server.key /etc/pgbouncer/ssl/server.crt /etc/pgbouncer/ssl/root.crt /etc/pgbouncer/ssl/root.key

echo "/etc/pgbouncer/ssl:"
ls -l /etc/pgbouncer/ssl

echo "Generating configuration files"
if test -n "${PG_HBA}"; then
  echo "${PG_HBA}" > /etc/pgbouncer/pg_hba.conf
fi

if test -n "${USERLIST}"; then
  echo "${USERLIST}" > /etc/pgbouncer/userlist.txt
fi

if test -n "${DB_MAPPING}"; then
  cat /etc/pgbouncer/pgbouncer.ini.template1 > ${PGBOUNCER_CONFIG}
  echo "${DB_MAPPING}" >> /etc/pgbouncer/pgbouncer.ini
  cat /etc/pgbouncer/pgbouncer.ini.template2 >> ${PGBOUNCER_CONFIG}
fi

if test -n "${EXTRA_CONFIG}"; then
  echo "${EXTRA_CONFIG}" >> ${PGBOUNCER_CONFIG}
fi


echo "Starting pgbouncer..."
exec pgbouncer -vvv -u ${PGBOUNCER_USER} ${PGBOUNCER_CONFIG}
