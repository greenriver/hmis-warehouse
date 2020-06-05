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

echo report seeding
bundle exec rake reports:seed

echo general seeding
bundle exec rake db:seed

echo translations
bundle exec rake gettext:sync_to_po_and_db

echo installing cron
./bin/cron_installer.rb
