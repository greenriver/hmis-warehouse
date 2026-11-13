###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.queued_tasks[:hmis_check_constraints] = -> do
  Hmis::Tasks::CheckConstraints.check_hud_constraints
end

if ENV['ENABLE_HMIS_API'] == 'true'
  Rails.application.config.queued_tasks[:hmis_populate_cded_reporting_keys_2_2026] = -> do
    HmisDataCleanup::PopulateCdedReportingKeys20260216.populate!
  end
end
