# Developer Setup
The warehouse application consists of three main parts:
1. The Rails Application Code
2. The Rails Application Database
3. The Warehouse Database

## Setup Your Development Environment
The warehouse is configured for development using Docker.  There are a variety of choices to make when setting up the warehouse, this document will lead you down the most simple path.

1. Clone the git repository
```
git clone git@github.com:greenriver/hmis-warehouse.git
```
2. Install Docker Desktop for your OS following the [instructions provided by Docker](https://www.docker.com/get-started).

3. Adjust the Docker Resources to allow up to 8GB of RAM.  See Docker -> Preferences -> Resources

4. If you have not previously setup [nginx-proxy](https://github.com/jwilder/nginx-proxy) to streamline local development. You should [follow the instructions here](developer-networking.md) before continuing.

5. Run the setup script
```
docker-compose run --rm shell bin/setup
```

6. Run the rails server
```
docker-compose run --rm web
```

## Anonymized Data
1. In your production environment, export a batch of anonymized data
```
bin/rake grda_warehouse:dump_hud_csvs_for_dev[2500]
```

2. In your development environment, place the exported files in folders in `var/hmis/<data_source_name>`

3. Import the batch
```
bin/rake grda_warehouse:import_dev_hud_csvs
```

4. Run through the daily imports, you may want to do this manually, though it can be done in a single pass with
```
bin/rake grda_warehouse:daily
```
