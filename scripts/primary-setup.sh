#!/bin/bash
set -e

# Run this script only on the Primary Pod
if [ "$(hostname)" != "postgres-0" ]; then
    exit 0
fi

echo "Configuring PostgreSQL Primary..."

# Enable streaming replication
cat >> "$PGDATA/postgresql.conf" <<EOF
listen_addresses = '*'
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
EOF

# Allow Standby servers to connect
cat >> "$PGDATA/pg_hba.conf" <<EOF
host replication ${REPLICATION_USER} 0.0.0.0/0 scram-sha-256
EOF

# Create the replication user
psql -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname postgres \
    --set=replication_user="$REPLICATION_USER" \
    --set=replication_password="$REPLICATION_PASSWORD" <<'SQL'

SELECT format(
    'CREATE ROLE %I WITH REPLICATION LOGIN PASSWORD %L',
    :'replication_user',
    :'replication_password'
) \gexec

SQL

echo "Primary configuration completed."
