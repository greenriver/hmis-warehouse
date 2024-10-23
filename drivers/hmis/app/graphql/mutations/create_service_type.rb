#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CreateServiceType < CleanBaseMutation
    graphql_name 'CreateServiceType'

    argument :input, Types::HmisSchema::ServiceTypeInput, required: true

    field :service_type, Types::HmisSchema::ServiceType, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      access_denied! unless current_user.can_configure_data_collection?
      errors = HmisErrors::Errors.new

      if !input.service_category_id && !input.service_category_name
        errors.add :service_category, :required
        return { errors: errors }
      end

      service_category = if input.service_category_id
        Hmis::Hud::CustomServiceCategory.find(input.service_category_id)
      else
        Hmis::Hud::CustomServiceCategory.new(
          name: input.service_category_name,
          user_id: hmis_user.user_id,
          data_source_id: current_user.hmis_data_source_id,
        )
      end

      category = Hmis::Hud::CustomServiceCategory.find(input.service_category_id)

      # Can't add a custom service to a HUD service category
      access_denied! if category.service_types.any?(&:hud_service?)

      service_type = Hmis::Hud::CustomServiceType.new(
        **input.to_params,
        user_id: hmis_user.user_id,
        data_source_id: current_user.hmis_data_source_id,
        custom_service_category: service_category,
      )

      if service_type.valid?
        service_type.save!
        { service_type: service_type }
      else
        errors.add_ar_errors(service_type.errors&.errors)
        { errors: errors }
      end
    end
  end
end
