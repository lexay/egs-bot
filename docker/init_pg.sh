set -e
echo 'Creating DB'
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE DATABASE epic;
EOSQL
echo 'Done creating DB'
