#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class RenameServiceCategory < CleanBaseMutation
    argument :id, ID, required: true
    argument :name, String, required: true

    field :service_category, Types::HmisSchema::ServiceCategory, null: true

    def resolve(id:, name:)
      access_denied! unless current_user.can_configure_data_collection?

      service_category = Hmis::Hud::CustomServiceCategory.find(id)
      service_category.name = name
      service_category.save!

      { service_category: service_category }
    end
  end
end
