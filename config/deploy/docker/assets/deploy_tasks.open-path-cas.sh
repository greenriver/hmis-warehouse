#!/bin/bash

set -eo pipefail

echo Migrating with individual rake tasks

echo Migrating app database
bundle exec rake db:migrate

echo bundle exec rake gettext:sync_to_po_and_db
bundle exec rake gettext:sync_to_po_and_db

echo bundle exec rake cas_seeds:create_rules
bundle exec rake cas_seeds:create_rules

echo bundle exec rake cas_seeds:create_match_decision_reasons
bundle exec rake cas_seeds:create_match_decision_reasons

echo bundle exec rake cas_seeds:ensure_all_match_routes_exist
bundle exec rake cas_seeds:ensure_all_match_routes_exist

echo bundle exec rake cas_seeds:ensure_all_match_prioritization_schemes_exist
bundle exec rake cas_seeds:ensure_all_match_prioritization_schemes_exist

echo bundle exec rake cas_seeds:stalled_reasons
bundle exec rake cas_seeds:stalled_reasons

echo bundle exec rake cas_seeds:create_mitigation_reasons
bundle exec rake cas_seeds:create_mitigation_reasons

echo installing cron
./bin/cron_installer.rb

# keep this always at the end of this file
echo making interface aware this script completed
bundle exec rake deploy:mark_deployment_id
echo ---DONE---
