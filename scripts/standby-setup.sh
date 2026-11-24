#!/bin/bash
set -e

PRIMARY_HOST="postgres-0.postgres-headless"
PRIMARY_PORT="5432"

echo "Starting Standby initialization..."

# Wait until Primary is ready
until pg_isready -h "$PRIMARY_HOST" \
                  -p "$PRIMARY_PORT" \
                  -U "$REPLICATION_USER"; do
    echo "Waiting for Primary..."
    sleep 5
done

# Bootstrap only if this is a fresh data directory
if [ ! -s "$PGDATA/PG_VERSION" ]; then

    echo "Taking base backup from Primary..."

    export PGPASSWORD="$REPLICATION_PASSWORD"

    pg_basebackup \
        -h "$PRIMARY_HOST" \
        -p "$PRIMARY_PORT" \
        -U "$REPLICATION_USER" \
        -D "$PGDATA" \
        -Fp \
        -Xs \
        -P \
        -R

    unset PGPASSWORD

    echo "Standby initialization completed."

else
    echo "Existing PostgreSQL data found."
fi

# Create password file AFTER base backup
export PGPASSFILE="$PGDATA/.pgpass"

printf '%s:%s:%s:%s:%s\n' \
    "$PRIMARY_HOST" \
    "$PRIMARY_PORT" \
    "*" \
    "$REPLICATION_USER" \
    "$REPLICATION_PASSWORD" > "$PGPASSFILE"

chmod 600 "$PGPASSFILE"

echo "Standby configuration completed."
