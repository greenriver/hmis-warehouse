#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  # TODO(#5737) - deprecated, to remove
  class DeleteServiceCategory < CleanBaseMutation
    argument :id, ID, required: true

    field :service_category, Types::HmisSchema::ServiceCategory, null: true

    def resolve(id:)
      access_denied! unless current_user.can_configure_data_collection?

      service_category = Hmis::Hud::CustomServiceCategory.find(id)

      # TODO: Eventually this should be a user-facing ValidationError returned in the {errors:} object
      raise 'Cannot delete a service category that has service types' if service_category.service_types.exists?

      default_delete_record(
        record: service_category,
        field_name: :service_category,
      )
    end
  end
end
