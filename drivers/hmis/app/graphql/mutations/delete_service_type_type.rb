#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class DeleteServiceTypeType < BaseMutation
    argument :id, ID, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:)
      raise 'access denied' unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find_by(id: id)
      raise HmisErrors::ApiError, 'Invalid service type ID' unless service_type

      is_empty = service_type.custom_services.count == 0
      raise HmisErrors::ApiError, 'Cannot delete a service type that has services' unless is_empty

      default_delete_record(
        record: service_type,
        field_name: :service_type,
      )
    end
  end
end
