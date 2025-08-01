###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AcHmis::CalculateAltAhaScore < CleanBaseMutation
    description 'Calculate alternative AHA score based on provided assessment values'

    argument :assessment_id, ID, required: true
    argument :values_by_link_id, Types::JsonObject, required: true

    field :score, Integer, null: true

    def resolve(assessment_id:, values_by_link_id:)
      errors = HmisErrors::Errors.new
      # Use AHA configuration as proxy to determine whether alt-AHA should be enabled
      errors.add :base, :server_error, full_message: 'AHA connection is not configured' unless HmisExternalApis::AcHmis::Aha.enabled?
      return { errors: errors } if errors.any?

      assessment = Hmis::Hud::CustomAssessment.find(assessment_id)
      access_denied! unless current_user.can_edit_enrollments_for(assessment.enrollment)

      aha_calculator = HmisExternalApis::AcHmis::AltAhaCalculator.new
      score = aha_calculator.calculate_score(assessment_id, values_by_link_id)

      { score: score }
    end
  end
end
