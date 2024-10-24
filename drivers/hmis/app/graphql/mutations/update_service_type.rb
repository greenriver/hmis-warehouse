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

      # Prevent users from unknowingly renaming/reusing HUD services for another purpose
      # while the service continues to collect HUD records for the original type.
      raise "Can't update HUD service type: #{service_type.id} #{service_type.name}" if service_type.hud_service?

      service_type.name = name
      service_type.supports_bulk_assignment = supports_bulk_assignment
      service_type.save!

      { service_type: service_type }
    end
  end
end
