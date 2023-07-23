###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::ValueBound < Types::BaseObject
    description 'Bound applied to the response value. The bound may or may not be dependent on another questions answer.'

    field :id, String, 'Unique identifier for this bound', null: false
    field :severity, Types::HmisSchema::Enums::ValidationSeverity, 'Severity of bound. If error, user will be unable to submit a value that does not meet this condition.', null: false
    field :type, Forms::Enums::BoundType, null: false
    field :offset, Integer, 'Value to offset the comparison value. Can be positive or negative. If date, offset is applied as number of days.', null: true

    # Note: only one of the below attributes should be specified
    field :value_number, Integer, null: true
    field :value_date, GraphQL::Types::ISO8601Date, null: true
    field :question, String, 'Link ID of dependent question, if this items value should be compared to another items value', null: true

    def severity
      object['severity'] || 'error'
    end
  end
end
