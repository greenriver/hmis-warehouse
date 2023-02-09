###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::AutofillValue < Types::BaseObject
    description 'Value to autofill based on conditional logic'

    # Value to autofill. Only 1 of the below should be specified
    field :value_code, String, 'Value to autofill if condition is met', null: true
    field :value_number, Integer, 'Value to autofill if condition is met', null: true
    field :value_boolean, Boolean, 'Value to autofill if condition is met', null: true
    field :sum_questions, [String], 'Link IDs of numeric questions to sum up and set as the value if condition is met', null: true

    # Condition specifying when to perform this autofill
    field :autofill_behavior, Types::Forms::Enums::EnableBehavior, null: false
    field :autofill_when, [Types::Forms::EnableWhen], null: false
  end
end
