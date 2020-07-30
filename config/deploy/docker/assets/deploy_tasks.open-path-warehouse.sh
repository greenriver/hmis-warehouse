#!/bin/sh

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
