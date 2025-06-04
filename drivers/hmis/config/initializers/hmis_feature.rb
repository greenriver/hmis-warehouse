###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# Hmis driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis)
#
# use with caution!

# frozen_string_literal: true

RailsDrivers.loaded << :hmis

Rails.application.config.queued_tasks[:hmis_check_constraints] = -> do
  Hmis::Tasks::CheckConstraints.check_hud_constraints
end

TodoOrDie('Remove one-time job', by: '2025-07-01')
if ENV['ENABLE_HMIS_API'] == 'true'
  Rails.application.config.queued_tasks[:hmis_migrate_unit_groups] = -> do
    MigrateUnitGroups20250604.new.perform
  end
end
