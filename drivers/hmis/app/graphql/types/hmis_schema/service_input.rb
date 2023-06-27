###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceInput < Types::BaseInputObject
    description 'HUD Service Input'
    argument :enrollment_id, ID, required: false
    argument :date_provided, GraphQL::Types::ISO8601Date, required: false
    argument :record_type, HmisSchema::Enums::Hud::RecordType, required: false
    argument :type_provided, HmisSchema::Enums::ServiceTypeProvided, required: false
    argument :other_type_provided, String, required: false
    argument :moving_on_other_type, String, required: false
    argument :sub_type_provided, HmisSchema::Enums::ServiceSubTypeProvided, required: false
    argument 'FAAmount', Float, required: false
    argument :referral_outcome, HmisSchema::Enums::Hud::PATHReferralOutcome, required: false

    def to_params
      result = to_h

      result[:record_type] = record_type || type_provided&.split(':')&.first&.to_i
      result[:type_provided] = type_provided&.split(':')&.last&.to_i
      result[:sub_type_provided] = sub_type_provided.split(':').last&.to_i if sub_type_provided.present?

      if enrollment_id.present?
        enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)

        result[:enrollment_id] = enrollment&.enrollment_id
        result[:personal_id] = enrollment&.personal_id
      end

      result
    end
  end
end
