#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class DeleteServiceTypeType < BaseMutation
    argument :id, ID, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find_by(id: id)
      raise HmisErrors::ApiError, 'Invalid service type ID' unless service_type

      default_delete_record(
        record: service_type,
        field_name: :service_type,
      )
    end
  end
end
