#!/bin/bash

set -eo pipefail

echo Storing Themed Maintenance Page
bundle exec rake maintenance:create

echo Migrating with individual rake tasks

echo Migrating app database
bundle exec rake db:migrate:primary

echo Migrating warehouse database
bundle exec rake db:migrate:warehouse

echo Migrating health database
bundle exec rake db:migrate:health

echo Migrating reporting database
bundle exec rake db:migrate:reporting

echo Report seeding
bundle exec rake reports:seed

echo General seeding
bundle exec rake db:seed

echo Translations
bundle exec rake gettext:sync_to_po_and_db

echo Installing cron
./bin/cron_installer.rb

# keep this always at the end of this file
echo Making interface aware this script completed
bundle exec rake deploy:mark_deployment_id
echo ---DONE---
