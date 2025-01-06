###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ServiceTypeInput < BaseInputObject
    description 'Create service type input'

    argument :name, String, required: false
    argument :service_category_id, ID, required: false
    argument :service_category_name, String, required: false
    argument :supports_bulk_assignment, Boolean, required: false

    def to_params
      to_h.except(:service_category_id, :service_category_name)
    end

    def find_or_initialize_service_category(user_id, data_source_id)
      # will be nil if neither is provided; that's fine for update (but not for create, which validates presence)
      if service_category_id.present?
        Hmis::Hud::CustomServiceCategory.find(service_category_id)
      elsif service_category_name.present?
        Hmis::Hud::CustomServiceCategory.where(
          data_source_id: data_source_id,
          name: service_category_name,
        ).first_or_initialize(user_id: user_id)
      end
    end
  end
end
