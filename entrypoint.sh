#!/bin/sh
set -e

FBBIN=/opt/firebird/bin
DATA=/var/lib/firebird/data
SECDB=/opt/firebird/security3.fdb

mkdir -p "$DATA"
chown -R firebird:firebird "$DATA" 2>/dev/null || true

# SYSDBA-Passwort bei jedem Start setzen (Embedded-Zugriff als firebird-User,
# Server laeuft noch nicht - so gehoeren auch die Lock-Dateien dem richtigen User)
if [ -n "$FIREBIRD_ROOT_PASSWORD" ]; then
    echo "create or alter user SYSDBA password '$FIREBIRD_ROOT_PASSWORD' using plugin Srp;" \
        | su firebird -s /bin/sh -c "$FBBIN/isql -q -user SYSDBA $SECDB"
fi

# Pruef-Datenbank anlegen, falls gewuenscht und nicht vorhanden
if [ -n "$FIREBIRD_DATABASE" ] && [ ! -f "$DATA/$FIREBIRD_DATABASE" ]; then
    echo "create database '$DATA/$FIREBIRD_DATABASE' default character set UTF8;" \
        | su firebird -s /bin/sh -c "$FBBIN/isql -q -user SYSDBA"
fi

exec su firebird -s /bin/sh -c "exec $FBBIN/firebird"
