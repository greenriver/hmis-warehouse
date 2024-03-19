#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class DeleteServiceType < CleanBaseMutation
    graphql_name 'DeleteServiceType'
    argument :id, ID, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:)
      access_denied! unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find(id)

      # TODO: Eventually this should be a user-facing ValidationError returned in the {errors:} object
      raise 'Cannot delete a service type that has services' if service_type.custom_services.exists?

      default_delete_record(
        record: service_type,
        field_name: :service_type,
      )
    end
  end
end
