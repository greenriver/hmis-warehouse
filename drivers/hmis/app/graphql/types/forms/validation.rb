###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Validation < Types::BaseObject
    description 'Conditions for a custom validation message'

    # The validation message and severity level
    field :message, String, 'Validation message to display', null: true
    field :severity, Types::HmisSchema::Enums::ValidationSeverity, 'Severity of validation. If error, user will be unable to submit if the specified condition is met.', null: false

    # Condition specifying when to display this validation
    field :error_behavior, Types::Forms::Enums::EnableBehavior, null: false
    field :error_when, [Types::Forms::EnableWhen], null: false

    def severity
      object['severity'] || 'error'
    end
  end
end
