###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::UnitGroupInput < BaseInputObject
    argument :project_id, ID, required: false
    argument :name, String, required: false
    argument :workflow_template_identifier, String, required: false
    argument :ce_event_type, HmisSchema::Enums::Hud::EventType, required: false
    argument :unit_type_id, ID, required: false
  end
end
