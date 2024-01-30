#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class HmisSchema::ClientAlertInput < BaseInputObject
    description 'Client Alert Input'

    argument :id, ID, required: true
    argument :note, String, required: true
    argument :expiration_date, GraphQL::Types::ISO8601Date, required: false
    argument :priority, Types::HmisSchema::Enums::ClientAlertPriorityLevel, required: false

    def to_params
      # TODO @martha pr - is this the correct place to attach client and created_by?
      h = to_h
      h['client'] = Hmis::Hud::Client.viewable_by(current_user).find(id)
      h['created_by'] = current_user
      h
    end
  end
end
