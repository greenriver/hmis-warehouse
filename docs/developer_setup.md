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

## Accessing the Site

If everything worked as designed your site should now be available at [https://hmis-warehouse.dev.test](https://hmis-warehouse.dev.test).  Any mail that the site sends will be delivered to [MailHog](https://github.com/mailhog/MailHog) which is availble at [https://mail.hmis-warehouse.dev.test](https://mail.hmis-warehouse.dev.test)

