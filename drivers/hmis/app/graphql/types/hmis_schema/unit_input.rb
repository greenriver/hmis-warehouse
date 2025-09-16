###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::UnitInput < BaseInputObject
    argument :project_id, ID, required: true
    argument :count, Integer, 'Number of units to create', required: false
    argument :prefix, String, 'Prefix for unit names', required: false
    argument :unit_type_id, ID, required: false
    argument :unit_group_id, ID, required: false
  end
end
