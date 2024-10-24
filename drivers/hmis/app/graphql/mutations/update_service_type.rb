#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class UpdateServiceType < CleanBaseMutation
    graphql_name 'UpdateServiceType'

    argument :id, ID, required: true
    argument :name, String, required: false, deprecation_reason: 'Deprecated in favor of input object'
    argument :supports_bulk_assignment, Boolean, required: false, deprecation_reason: 'Deprecated in favor of input object'

    argument :input, Types::HmisSchema::ServiceTypeInput, required: false # TODO(#5737) Make required

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:, name: nil, supports_bulk_assignment: nil, input: nil)
      access_denied! unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find(id)

      # Prevent users from unknowingly renaming/reusing HUD services for another purpose
      # while the service continues to collect HUD records for the original type.
      raise "Can't update HUD service type: #{service_type.id} #{service_type.name}" if service_type.hud_service?

      if input.present?
        service_type.assign_attributes(**input.to_params) unless input.to_params.empty?

        service_category = input.get_or_create_service_category(hmis_user.user_id, current_user.hmis_data_source_id)
        service_type.custom_service_category = service_category if service_category.present?
      else
        service_type.name = name
        service_type.supports_bulk_assignment = supports_bulk_assignment
      end

      if service_type.valid?
        service_type.save!
        { service_type: service_type }
      else
        errors = HmisErrors::Errors.new
        errors.add_ar_errors(service_type.errors&.errors)
        { errors: errors }
      end
    end
  end
end
