###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ServiceTypeInput < BaseInputObject
    description 'Create service type input'

    argument :name, String, required: true
    argument :service_category_id, ID, required: false
    argument :service_category_name, String, required: false
    argument :supports_bulk_assignment, Boolean, required: false

    def to_params
      to_h.except(:service_category_id, :service_category_name)
    end
  end
end
