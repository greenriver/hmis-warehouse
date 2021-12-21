#!/bin/bash

set -eo pipefail

# strip extension installation to avoid permissions failures
# use sed -i.bak syntax for cross compatibility with macos and linux
sed -i.bak '/EXTENSION/d' db/structure.sql
sed -i.bak '/EXTENSION/d' db/health/structure.sql
sed -i.bak '/EXTENSION/d' db/reporting/structure.sql
sed -i.bak '/EXTENSION/d' db/warehouse/structure.sql

# Only enable for initial deployments to new installations
# TODO: fix the bootstra_databases! method in roll_out.rb to handle a first install
# ./bin/db_prep

echo Compiling and pushing assets
bundle exec rake assets:clobber
bundle exec rake assets:precompile
aws s3 sync ./public/assets s3://openpath-precompiled-assets/$ASSETS_PREFIX/$GITHASH

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
