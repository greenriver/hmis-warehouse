#!/bin/bash

set -eo pipefail

# strip extension installation to avoid permissions failures
# use sed -i.bak syntax for cross compatibility with macos and linux
sed -i.bak '/EXTENSION/d' db/structure.sql
sed -i.bak '/EXTENSION/d' db/health_structure.sql
sed -i.bak '/EXTENSION/d' db/reporting_structure.sql
sed -i.bak '/EXTENSION/d' db/warehouse_structure.sql

# Only enable for initial deployments to new installations
# TODO: fix the bootstra_databases! method in roll_out.rb to handle a first install
./bin/db_prep

echo Storing Themed Maintenance Page
T1=`date +%s`
bundle exec rake maintenance:create
T2=`date +%s`
echo "... rake maintenance:create took $(expr $T2 - $T1) seconds"

echo Migrating with individual rake tasks

echo Migrating app database
T1=`date +%s`
bundle exec rake db:migrate:primary
T2=`date +%s`
echo "...rake db:migrate:primary took $(expr $T2 - $T1) seconds"

echo Migrating warehouse database
T1=`date +%s`
bundle exec rake db:migrate:warehouse
T2=`date +%s`
echo "...rake db:migrate:warehouse took $(expr $T2 - $T1) seconds"

echo 'Migrating health database'
T1=`date +%s`
bundle exec rake db:migrate:health
T2=`date +%s`
echo "...rake db:migrate:health took $(expr $T2 - $T1) seconds"

echo 'Migrating reporting database'
T1=`date +%s`
bundle exec rake db:migrate:reporting
T2=`date +%s`
echo "...rake db:migrate:reporting took $(expr $T2 - $T1) seconds"

echo 'Report seeding'
T1=`date +%s`
bundle exec rake reports:seed
T2=`date +%s`
echo "...rake reports:seed took $(expr $T2 - $T1) seconds"

echo 'General seeding'
T1=`date +%s`
bundle exec rake db:seed
T2=`date +%s`
echo "...rake db:seed took $(expr $T2 - $T1) seconds"

echo 'Translations'
T1=`date +%s`
bundle exec rake gettext:sync_to_po_and_db
T2=`date +%s`
echo "...rake gettext:sync_to_po_and_db took $(expr $T2 - $T1) seconds"

echo 'Installing cron'
T1=`date +%s`
./bin/cron_installer.rb
T2=`date +%s`
echo "..../bin/cron_installer.rb took $(expr $T2 - $T1) seconds"

# keep this always at the end of this file
echo Making interface aware this script completed
bundle exec rake deploy:mark_deployment_id
echo ---DONE---
