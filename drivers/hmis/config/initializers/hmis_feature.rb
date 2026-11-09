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

  # The FORM_DEFINITION static form was replaced by a dialog built in the frontend. Its seeded
  # definition now has an unknown role, so remove it.
  Rails.application.config.queued_tasks[:hmis_remove_form_definition_static_form_2026_11] = -> do
    Hmis::Form::Definition.where(role: 'FORM_DEFINITION').delete_all
  end
end
