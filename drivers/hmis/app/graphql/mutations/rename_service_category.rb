#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class RenameServiceCategory < BaseMutation
    argument :id, ID, required: true
    argument :name, String, required: true

    field :service_category, Types::HmisSchema::ServiceCategory, null: true

    def resolve(id:, name:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      service_category = Hmis::Hud::CustomServiceCategory.find_by(id: id)
      raise HmisErrors::ApiError, 'Invalid service category ID' unless service_category

      service_category.name = name
      service_category.save!

      { service_category: service_category }
    end
  end
end
