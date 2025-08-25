###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class CustomAssessmentProcessor < Base
    def factory_name
      :owner_factory
    end

    def relation_name
      :custom_assessment
    end

    def schema
      Types::HmisSchema::Assessment
    end

    def information_date(_)
    end

    def post_process
      validate_alt_aha_score
    end

    private

    # Validate Alt-AHA score if present. For more information on Alt-AHA score see https://docs.google.com/document/d/1Gcz9-t_utRcqGV9xCzQvTehjQOCqqPv_5-JY_IhhL4Q/edit?tab=t.0#heading=h.kpe3ch74jsjj
    # If assessment contained an Alt-AHA score calculation, validate it by re-calculating the score.
    # If the scores don't match, return a validation error.
    # This prevents users from submitting scores that do not match the current form values.
    def validate_alt_aha_score
      alt_aha_item = @processor.definition.link_id_item_hash.values.find { |i| i.component == 'ALT_AHA' }
      return unless alt_aha_item # alt-aha not collected on this form, nothing to validate

      alt_aha_custom_field_key = alt_aha_item.dig('mapping', 'custom_field_key')
      raise 'Alt-AHA form item does not map to a custom field' unless alt_aha_custom_field_key # unexpected

      value = @hud_values.fetch(alt_aha_custom_field_key)
      return unless value # Skip if there's no score to validate
return if value == HIDDEN_FIELD_VALUE

      # Recalculate score to confirm that it is unchanged
      aha_calculator = HmisExternalApis::AcHmis::AltAhaCalculator.new(
        values_by_link_id: @processor.values,
        client: @processor.client_factory,
        user: @processor.current_user,
        owner: @processor.enrollment_factory,
        form_definition_identifier: @processor.definition.identifier,
      )
      score, = aha_calculator.calculate_score

      return if score == value # submitted score and recalculated score match, validation succeeded

      @processor.add_processing_error(
        HmisErrors::Error.new(
          alt_aha_custom_field_key,
          readable_attribute: alt_aha_item.brief_text || alt_aha_item.text,
          link_id: alt_aha_item.link_id,
          section: @processor.definition.link_id_section_hash[alt_aha_item.link_id],
          message: 'value has changed, and needs to be recalculated before submission',
        ),
      )
    end
  end
end
