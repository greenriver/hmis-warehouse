###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AcHmis::CalculateAltAhaScore < CleanBaseMutation
    description 'Calculate alternative AHA score based on provided assessment values'

    argument :enrollment_id, ID, required: true
    argument :form_definition_identifier, String, required: true
    argument :values_by_link_id, Types::JsonObject, required: true

    field :score, Integer, null: true

    def resolve(enrollment_id:, form_definition_identifier:, values_by_link_id:)
      # Use AHA configuration as proxy to determine whether alt-AHA should be enabled
      # Raise instead of returning an error. (Not fixable by the user filling out the form)
      raise 'AHA connection is not configured' unless HmisExternalApis::AcHmis::Aha.enabled?

      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find(enrollment_id)
      access_denied! unless current_user.can_edit_enrollments_for?(enrollment)

      aha_calculator = HmisExternalApis::AcHmis::AltAhaCalculator.new(
        values_by_link_id: values_by_link_id,
        client: enrollment.client,
        user: current_user,
        owner: enrollment,
        form_definition_identifier: form_definition_identifier,
      )

      # Check for missing required responses
      required_link_ids = aha_calculator.required_link_ids

      # Use form validation to validate that the required link IDs were provided in the form submission.
      # This lets us reuse the form validator's logic for skipping questions that weren't shown to the user
      # (such as dependent questions whose conditions were not met).
      definition = Hmis::Form::Definition.published.find_by(identifier: form_definition_identifier)
      validations = definition.validate_form_values(values_by_link_id, link_ids: required_link_ids)

      if validations.any?
        # Just return a generic message, not the specific validations that failed
        errors = HmisErrors::Errors.new
        errors.add :base, :required, full_message: 'Unable to calculate score. Please finish entering responses.'
        return { errors: errors }
      end

      score, = aha_calculator.calculate_score

      { score: score }
    end
  end
end
