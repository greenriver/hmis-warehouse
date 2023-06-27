docker compose stop pg12 db

docker compose up -d pg12 db

sleep 3

export FILENAME=pg12.dumpall.sql

# docker compose exec pg12 pg_dumpall --help

mkdir -p tmp/dumps

echo Dumping pg12
docker compose exec \
  pg12 pg_dumpall \
  --exclude-database=template\* \
  --exclude-database=postgres \
  > tmp/dumps/$FILENAME

echo Importing pg13
docker compose exec \
  db psql -c "\i /tmp/dumps/$FILENAME"

docker compose down pg12
