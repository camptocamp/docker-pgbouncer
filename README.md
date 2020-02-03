# Pgbouncer

PostgreSQL connection pooler.

pgbouncer 1.12 (from debian/testing) rebuilt on debian-buster. 

## Tags

- `latest`: Same as `debian-buster`.
- `debian-buster`: `pgbouncer-1.12.0` on `debian:buster` ([Dockerfile](https://github.com/camptocamp/docker-pgbouncer/blob/master/Dockerfile))

## Usage

Environment variables:

* CA_CERT or CA_CERT_FILENAME (mandatory): CA_CERT contains the CA certificate,
  while CA_CERT_FILENAME is the path to a file containing the certificate.

* CA_KEY or CA_KEY_FILENAME (mandatory): you need to pass one of these. CA_KEY
  contains the CA key, while CA_KEY_FILENAME is the path to a file containing
  the key.

* SERVER_KEY_SUBJECT (optional): the subject of the server key that will be
  generated (and placed in a volume) if none exist. Defaults to a reasonable value for Camptocamp.

* PG_HBA: the content to be put in the pg_hba configuration for pgbouncer

* USERLIST: the content to be put in the userlist.txt file

* DB_MAPPING: the content to be put in the middle of the pgbouncer.ini file

* EXTRA_CONFIG: the content to be places at the end of the pgbouncer.ini file

# Network ports

By default, pgbouncer listens on:

    0.0.0.0:6432


# Tips

## Content of USERLIST

When using md5 in pg_hba.conf, generate the md5 password with:
```
$ echo -n "md5"; echo -n "<password><user>" | md5sum | awk '{print $1}'
```
Then fill in userlist.txt with one line per allowed user:
```
"<user>" "<md5_password>"
```


## To generate a CA key and certificate

```
openssl req -new -nodes -text -out root.csr  -keyout root.key -subj "/C=CH/ST=Vaud/L=Lausanne/O=Camptocamp S.A./OU=BS/CN=ca/"
openssl x509 -req -in root.csr -text -days 3650 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey root.key -out root.crt
```

-> you want `root.key` and `root.crt`. Keep them somewhere safe. 

## To use client key authentication

Set EXTRA_CONFIG to

```
ignore_startup_parameters = extra_float_digits\n
client_tls_sslmode = allow\n
client_tls_key_file = /etc/pgbouncer/ssl/server.key\n
client_tls_cert_file = /etc/pgbouncer/ssl/server.crt\n
client_tls_ca_file = /etc/pgbouncer/ssl/root.crt
```

And for the databases for which you need client key auth, use in PG_HBA:

hostssl <dbname> all 0.0.0.0/0 cert

