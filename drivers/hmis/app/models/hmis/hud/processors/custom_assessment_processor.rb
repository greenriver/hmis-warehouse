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

    def process_custom_field(field, value)
      alt_aha_link_id = 'alt_aha_score'
      alt_aha_item = @processor.definition.link_id_item_hash[alt_aha_link_id]
      alt_aha_custom_field_key = alt_aha_item&.dig('mapping', 'custom_field_key')

      if field == alt_aha_custom_field_key
        # Special case: recalculate score to confirm it is unchanged
        aha_calculator = HmisExternalApis::AcHmis::AltAhaCalculator.new(
          values_by_link_id: @processor.values,
          client: @processor.client_factory,
          user: @processor.current_user,
          owner: @processor.owner_factory, # owner is the CustomAssessment that's also the owner of this FormProcessor
          form_definition_identifier: @processor.definition.identifier,
        )
        score, calculation_log = aha_calculator.calculate_score

        # Add calculation log to the assessment; rails will auto-save if the assessment is valid
        @processor.owner_factory.calculation_logs << calculation_log

        unless score == value
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

      super(field, value)
    end
  end
end
