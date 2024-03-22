###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ServiceTypeInput < BaseInputObject
    description 'Create service type input'

    argument :name, String, required: true
    argument :service_category_id, ID, required: true
    argument :supports_bulk_assignment, Boolean, required: false

    def to_params
      result = to_h.except(:service_category_id)
      result[:custom_service_category_id] = service_category_id
      result
    end
  end
end
