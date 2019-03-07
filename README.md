# Pgbouncer

PostgreSQL connection pooler.

Simple out-of-box `pgbouncer` for debian.

## Tags

- `latest`: Same as `debian-jessie`.
- `debian-jessie`: `pgbouncer-1.5.4` on `debian:jessie` ([Dockerfile](https://github.com/Kotaimen/docker-pgbouncer/blob/debian-jessie/Dockerfile))

[![](https://badge.imagelayers.io/kotaimen/pgbouncer:latest.svg)](https://imagelayers.io/?images=kotaimen/pgbouncer:latest 'Get your own badge on imagelayers.io')

## Usage

Mount your configuration directory as a volume:

    docker run -v <pgbouncer_config_dir>:/etc/pgbouncer:ro pgbouncer

You can use [supplied config files](https://github.com/Kotaimen/docker-pgbouncer/tree/develop/pgbouncer), which are copied from a fresh debian installation.  Also check pgbouncer's official [config file documentation](https://pgbouncer.github.io/config.html).

By default, pbbouncer listens on:

    0.0.0.0:6432

Default user and password are : user/password

Content of userlist.txt. When using md5 in pg_hba.conf, generate the md5 password with:
```
$ echo -n "md5"; echo -n "<password><user>" | md5sum | awk '{print $1}'
```
Then fill in userlist.txt with one line per allowed user:
```
"<user>" "<md5_password>"
```
