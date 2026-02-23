###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class UpdateServiceType < CleanBaseMutation
    graphql_name 'UpdateServiceType'

    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ServiceTypeInput, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true

    def resolve(id:, input:)
      access_denied! unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.find(id)

      # Prevent users from unknowingly renaming/reusing HUD services for another purpose
      # while the service continues to collect HUD records for the original type.
      raise "Can't update HUD service type: #{service_type.id} #{service_type.name}" if service_type.hud_service?

      service_type.assign_attributes(**input.to_params) unless input.to_params.empty?

      service_category = input.find_or_initialize_service_category(hud_user.user_id, current_user.hmis_data_source_id)
      service_type.custom_service_category = service_category if service_category.present?

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
