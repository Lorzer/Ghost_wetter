#!/bin/bash
set -e

echo "Starting Railway entrypoint..."

# Wait for MySQL to be ready
echo "Waiting for database connection..."
MAX_RETRIES=30
RETRY_COUNT=0

until node -e "
  const mysql = require('mysql2/promise');
  (async () => {
    try {
      const host = process.env.database__connection__host || process.env.MYSQLHOST || 'localhost';
      const user = process.env.database__connection__user || process.env.MYSQLUSER || 'root';
      const password = process.env.database__connection__password || process.env.MYSQLPASSWORD || '';
      const database = process.env.database__connection__database || process.env.MYSQLDATABASE || 'ghost';
      
      const connection = await mysql.createConnection({
        host: host,
        user: user,
        password: password,
        database: database,
        connectTimeout: 5000
      });
      await connection.ping();
      await connection.end();
      console.log('Database connection successful');
      process.exit(0);
    } catch (e) {
      console.error('Database not ready:', e.message);
      process.exit(1);
    }
  })();
" 2>/dev/null; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "Failed to connect to database after $MAX_RETRIES attempts. Exiting."
    exit 1
  fi
  echo "Database not ready, waiting 2 seconds... (attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
done

echo "Database is ready!"

# Run migrations
echo "Running database migrations..."
cd /home/ghost/ghost/core

# Check for knex-migrator in multiple possible locations (yarn workspace hoisting)
if [ -f "./node_modules/.bin/knex-migrator" ]; then
  KnexMigrator="./node_modules/.bin/knex-migrator"
elif [ -f "../../node_modules/.bin/knex-migrator" ]; then
  KnexMigrator="../../node_modules/.bin/knex-migrator"
elif [ -f "/home/ghost/node_modules/.bin/knex-migrator" ]; then
  KnexMigrator="/home/ghost/node_modules/.bin/knex-migrator"
else
  KnexMigrator=""
fi

if [ -n "$KnexMigrator" ]; then
  $KnexMigrator migrate --init-if-missing || {
    echo "Warning: Migration failed or database already initialized. Continuing..."
  }
else
  echo "Warning: knex-migrator not found. Skipping migrations."
fi

# Start Ghost
echo "Starting Ghost..."
exec "$@"

