###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteService < BaseMutation
    argument :id, ID, required: true

    field :service, Types::HmisSchema::Service, null: true

    def resolve(id:)
      raise HmisErrors::ApiError, 'Invalid service ID' unless Hmis::Hud::HmisService.valid_id?(id)

      # hmis_service is the HmisService view row representing this service.
      hmis_service = Hmis::Hud::HmisService.viewable_by(current_user).find_by(id: id)
      # owner is the actual service record, either a Hmis::Hud::Service or Hmis::Hud::CustomService.
      owner = hmis_service&.owner
      access_denied! unless hmis_service.present? && owner.present? && policy_for(owner.enrollment, policy_type: :hmis_enrollment).can_edit?

      owner.destroy!

      {
        service: hmis_service,
        errors: [],
      }
    end
  end
end
