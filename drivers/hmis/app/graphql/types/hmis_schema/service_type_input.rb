###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

    def get_or_create_service_category(user_id, data_source_id)
      service_category = if service_category_id.present?
        Hmis::Hud::CustomServiceCategory.find(service_category_id)
      elsif service_category_name.present?
        Hmis::Hud::CustomServiceCategory.new(
          name: service_category_name,
          user_id: user_id,
          data_source_id: data_source_id,
        )
      end
      # will be nil if neither is provided; that's fine for update (but not for create, which validates presence)

      # Can't add a custom service to a HUD service category
      raise 'access denied' if service_category&.service_types&.any?(&:hud_service?)

      service_category
    end
  end
end
