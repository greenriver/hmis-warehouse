#!/bin/bash

set -eo pipefail

echo loading the sql structure on first deployment
echo loading app structure
bundle exec rake db:structure:conditional_load
echo loading warehouse structure
bundle exec rake warehouse:db:structure:conditional_load
echo loading health structure
bundle exec rake health:db:structure:conditional_load
echo loading reporting structure
bundle exec rake reporting:db:structure:conditional_load

echo done loading all the structure files.


echo Storing Themed Maintenance Page
bundle exec rake maintenance:create

echo Migrating with individual rake tasks

echo Migrating app database
bundle exec rake db:migrate

echo Migrating warehouse database
bundle exec rake warehouse:db:migrate

echo Migrating health database
bundle exec rake health:db:migrate

echo Migrating reporting database
bundle exec rake reporting:db:migrate

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
