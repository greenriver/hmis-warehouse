###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ServiceTypeInput < BaseInputObject
    description 'Create service type input'

    argument :name, String, required: true
    argument :custom_service_category_id, ID, required: true
    argument :hud_record_type, ID, required: false
    argument :hud_type_provided, ID, required: false
    argument :supports_bulk_assignment, Boolean, required: false

    def to_params
      to_h
    end
  end
end
