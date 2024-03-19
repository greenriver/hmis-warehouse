#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class RenameServiceTypeType < BaseMutation
    argument :id, ID, required: true
    argument :name, String, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:, name:)
      raise 'access denied' unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find_by(id: id)
      raise HmisErrors::ApiError, 'Invalid service type ID' unless service_type

      service_type.name = name
      service_type.save!

      { service_type: service_type }
    end
  end
end
