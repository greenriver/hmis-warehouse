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
2. [Install Colima for your OS](https://github.com/abiosoft/colima).  Mac instructions below.

```
brew install lima colima docker docker-compose direnv
colima template
```

Adjust the following settings:
```
cpu: 8
memory: 16
vmType: vz
rosetta: true
mountType: virtiofs
```
Setup colima to start on boot
```
colima stop
brew services colima start
```

4. If you have not previously setup [traefik](http://traefik.io/) to streamline local development. You should [follow the instructions here](developer-networking.md) before continuing.

5. Copy in the sample environment variable
```
cp sample.env .env.local.development
touch .env.local
```

6. Run the setup script
```
docker-compose run --rm shell bin/setup
```

7. Run the rails server
```
docker-compose run --rm web
```

## Accessing the Site

If everything worked as designed your site should now be available at [https://hmis-warehouse.dev.test](https://hmis-warehouse.dev.test).  Any mail that the site sends will be delivered to [MailHog](https://github.com/mailhog/MailHog) which is availble at [https://mail.hmis-warehouse.dev.test](https://mail.hmis-warehouse.dev.test)

## Loading Data
At this point, you'll probably want to [load some sample HMIS data](developer_data.md).

## Running E2E Tests
See [spec/support/E2E_README.md](../spec/support/E2E_README.md).
