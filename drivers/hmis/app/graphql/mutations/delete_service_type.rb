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
      raise "Can't delete HUD service type: #{service_type.id} #{service_type.name}" if service_type.hud_service?

      # Can't delete service type that already has services
      if service_type.custom_services.exists?
        errors = HmisErrors::Errors.new
        errors.add :base, :invalid, full_message: 'Cannot delete a service type that has services'
        return { errors: errors }
      end

      default_delete_record(
        record: service_type,
        field_name: :service_type,
      )
    end
  end
end
