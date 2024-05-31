#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class UpdateServiceType < CleanBaseMutation
    graphql_name 'UpdateServiceType'

    argument :id, ID, required: true
    argument :name, String, required: true
    argument :supports_bulk_assignment, Boolean, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:, name:, supports_bulk_assignment:)
      access_denied! unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find(id)
      service_type.name = name
      service_type.supports_bulk_assignment = supports_bulk_assignment
      service_type.save!

      { service_type: service_type }
    end
  end
end
