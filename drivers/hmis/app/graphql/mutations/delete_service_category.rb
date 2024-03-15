#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class DeleteServiceCategory < BaseMutation
    argument :id, ID, required: true

    field :service_category, Types::HmisSchema::ServiceCategory, null: true

    def resolve(id:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      service_category = Hmis::Hud::CustomServiceCategory.find_by(id: id)
      raise HmisErrors::ApiError, 'Invalid service category ID' unless service_category

      result = default_delete_record(
        record: service_category,
        field_name: :service_category,
      )

      # Return the service category object
      result[:service_category] = service_category

      result
    end
  end
end
