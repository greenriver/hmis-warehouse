###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteService < BaseMutation
    argument :id, ID, required: true

    field :service, Types::HmisSchema::Service, null: true

    def resolve(id:)
      raise HmisErrors::ApiError, 'Invalid service ID' unless Hmis::Hud::HmisService.valid_id?(id)

      hmis_service = Hmis::Hud::HmisService.viewable_by(current_user).find_by(id: id)
      result = default_delete_record(
        record: hmis_service&.owner,
        field_name: :service,
        permissions: :can_edit_enrollments,
      )

      # Return the HmisService object
      result[:service] = hmis_service

      result
    end
  end
end
