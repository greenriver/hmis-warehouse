###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def to_client
      attributes = to_h.except(:gender)
      hud_user = Hmis::Hud::User.system_user(data_source_id: GrdaWarehouse::DataSource.hmis.pluck(:id).first)
      Hmis::Hud::Client.new(
        **attributes,
        **Hmis::Hud::Processors::ClientProcessor.gender_attributes(gender || []),
        **HudUtility.races.keys.map { |k| [k, 99] }.to_h,
        ethnicity: 99,
        name_data_quality: 1,
        dob_data_quality: 1,
        ssn_data_quality: ssn.present? ? 1 : 99,
        veteran_status: 99,
        user: hud_user,
      )
    end
  end
end
