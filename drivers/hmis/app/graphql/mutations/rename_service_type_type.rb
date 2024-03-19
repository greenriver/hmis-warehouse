#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class RenameServiceTypeType < CleanBaseMutation
    argument :id, ID, required: true
    argument :name, String, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:, name:)
      access_denied! unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find(id)
      service_type.name = name
      service_type.save!

      { service_type: service_type }
    end
  end
end
