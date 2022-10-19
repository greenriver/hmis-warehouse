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
    date_string_argument :date_provided, 'Date with format yyyy-mm-dd', required: false
    argument :record_type, HmisSchema::Enums::RecordType, required: false
    argument :type_provided, HmisSchema::Enums::ServiceTypeProvided, required: false
    argument :other_type_provided, String, required: false
    argument :moving_on_other_type, String, required: false
    argument :sub_type_provided, HmisSchema::Enums::ServiceSubTypeProvided, required: false
    argument 'FAAmount', Float, required: false
    argument :referral_outcome, HmisSchema::Enums::PATHReferralOutcome, required: false

    def to_params
      result = to_h

      result[:type_provided] = type_provided.split(':').last&.to_i if type_provided.present?
      result[:sub_type_provided] = sub_type_provided.split(':').last&.to_i if sub_type_provided.present?

      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)

      if enrollment.present?
        result[:enrollment_id] = enrollment.enrollment_id
        result[:personal_id] = enrollment.personal_id
      end

      result
    end
  end
end
