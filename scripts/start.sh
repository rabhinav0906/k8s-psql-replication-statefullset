#!/bin/bash
set -e

POD_NAME=$(hostname)

echo "Starting PostgreSQL Pod: $POD_NAME"

export PGPASSFILE="$PGDATA/.pgpass"

# Primary Pod
if [ "$POD_NAME" = "postgres-0" ]; then

    echo "Initializing PostgreSQL as Primary..."

    exec /usr/local/bin/docker-entrypoint.sh postgres

# Standby Pods
else

    echo "Initializing PostgreSQL as Standby..."

    # Ensure PostgreSQL owns the persistent data directory
    if [ "$(id -u)" -eq 0 ]; then
        mkdir -p "$PGDATA"
        chown -R postgres:postgres "$PGDATA"
    fi

    # Bootstrap only if database is empty
    if [ ! -s "$PGDATA/PG_VERSION" ]; then

        echo "Taking backup from Primary..."

        if [ "$(id -u)" -eq 0 ]; then
            gosu postgres bash /scripts/standby-setup.sh
        else
            bash /scripts/standby-setup.sh
        fi

    else
        echo "Existing Standby database found."
    fi

    echo "Starting PostgreSQL..."

    exec /usr/local/bin/docker-entrypoint.sh postgres

fi
