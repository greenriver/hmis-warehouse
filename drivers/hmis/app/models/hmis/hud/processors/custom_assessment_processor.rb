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
      if field == 'housing_needs_alt_aha_score'
        aha_calculator = HmisExternalApis::AcHmis::AltAhaCalculator.new(
          values_by_link_id: @processor.values,
          client: @processor.client_factory,
          user: @processor.current_user,
          owner: @processor.owner_factory, # owner is the CustomAssessment that's also the owner of this FormProcessor
          form_definition_identifier: @processor.definition.identifier,
        )
        score = aha_calculator.calculate_score

        raise unless score == value
      end

      super(field, value)
    end
  end
end
