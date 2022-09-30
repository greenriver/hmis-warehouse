###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceInput < Types::BaseInputObject
    description 'HUD Service Input'
    argument :enrollment_id, ID, required: false
    argument :client_id, ID, required: false
    date_string_argument :date_provided, 'Date with format yyyy-mm-dd', required: false
    argument :record_type, HmisSchema::Enums::RecordType, required: false
    argument :type_provided, HmisSchema::Enums::ServiceTypeProvided, required: false
    argument :other_type_provided, String, required: false
    argument :moving_on_other_type, String, required: false
    argument :sub_type_provided, HmisSchema::Enums::ServiceSubTypeProvided, required: false
    argument 'FAAmount', Float, required: false
    argument :referral_outcome, HmisSchema::Enums::PATHReferralOutcome, required: false

    def to_params
      result = to_h.except(:type_provided, :sub_type_provided, :enrollment_id, :client_id)

      result[:type_provided] = type_provided.split(':').last&.to_i if type_provided.present?
      result[:sub_type_provided] = sub_type_provided.split(':').last&.to_i if sub_type_provided.present?

      result[:enrollment_id] = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)&.enrollment_id if enrollment_id.present?
      result[:personal_id] = Hmis::Hud::Client.find_by(id: client_id)&.personal_id if client_id.present?

      result
    end
  end
end
