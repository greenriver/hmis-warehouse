#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  # TODO(#5737) - deprecated, to remove
  class CreateServiceCategory < CleanBaseMutation
    argument :name, String, required: true

    field :service_category, Types::HmisSchema::ServiceCategory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(name:)
      access_denied! unless current_user.can_configure_data_collection?

      service_category = Hmis::Hud::CustomServiceCategory.new(
        name: name,
        user_id: hmis_user.user_id,
        data_source_id: current_user.hmis_data_source_id,
      )

      if service_category.valid?
        service_category.save!
        { service_category: service_category }
      else
        errors = HmisErrors::Errors.new
        errors.add_ar_errors(service_category.errors)
        { errors: errors }
      end
    end
  end
end
