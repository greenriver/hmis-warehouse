###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class AcHmis::MciClearanceInput < Types::BaseInputObject
    argument :first_name, String, required: true
    argument :middle_name, String, required: false
    argument :last_name, String, required: true
    argument :ssn, String, required: false
    argument :dob, GraphQL::Types::ISO8601Date, required: true
    argument :gender, [Types::HmisSchema::Enums::Gender], required: false

    def self.to_client(attributes_hash, user)
      attributes = attributes_hash.except(:gender)
      genders = attributes_hash[:gender] || []
      hud_user = Hmis::Hud::User.system_user(data_source_id: user.hmis_data_source_id)
      Hmis::Hud::Client.new(
        **attributes,
        **Hmis::Hud::Processors::ClientProcessor.gender_attributes(genders),
        **HudUtility2024.races.keys.map { |k| [k, 99] }.to_h,
        name_data_quality: 1,
        dob_data_quality: 1,
        ssn_data_quality: attributes[:ssn].present? ? 1 : 99,
        veteran_status: 99,
        user: hud_user,
      )
    end

    def to_client
      self.class.to_client(to_h, current_user)
    end
  end
end
