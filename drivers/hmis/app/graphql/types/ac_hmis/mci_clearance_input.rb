###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class AcHmis::MciClearanceInput < Types::BaseInputObject
    argument :first_name, String
    argument :middle_name, String
    argument :last_name, String, required: true
    argument :ssn, String, required: true
    argument :dob, GraphQL::Types::ISO8601Date, required: true
    argument :gender, [Types::HmisSchema::Enums::Gender], required: true

    def to_client
      attributes = to_h.except(:gender)
      Hmis::Hud::Client.new(
        **attributes,
        **Hmis::Hud::Processors::ClientProcessor.gender_attributes(gender),
      )
    end
  end
end
