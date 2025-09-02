# Receiving Mail During Development

It's often very helpful to be able to see and test mail in development.  We handle mail external to the Warehouse and CAS with [MailHog](https://github.com/mailhog/MailHog).  The Mailhog server is setup using Docker Compose on the Traefik network.

## Setup
1. Add `127.0.0.1 mailhog.dev.test` to `/etc/hosts`
2. Create a `mailhog` directory outside of the Warehouse and CAS repository folders
3. Copy the `docker-compose.yml` [file in this directory](./docker-compose.yml) to your new `mailhog` directory
4. `docker-compose up -d`

## Access MailHog
MailHog should now be running at `https://mailhog.dev.test`.
