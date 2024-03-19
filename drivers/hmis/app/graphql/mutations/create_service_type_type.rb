#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CreateServiceTypeType < CleanBaseMutation
    argument :input, Types::HmisSchema::ServiceTypeInput, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      access_denied! unless current_user.can_configure_data_collection?

      service_type = Hmis::Hud::CustomServiceType.new(
        **input.to_params,
        user_id: hmis_user.user_id,
        data_source_id: current_user.hmis_data_source_id,
      )

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
