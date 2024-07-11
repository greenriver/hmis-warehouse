###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::AutofillValue < Types::BaseObject
    skip_activity_log
    description 'Value to autofill based on conditional logic'

    # Value to autofill. Only 1 of the below should be specified
    field :value_code, String, 'Value to autofill if condition is met', null: true
    field :value_number, Integer, 'Value to autofill if condition is met', null: true
    field :value_boolean, Boolean, 'Value to autofill if condition is met', null: true
    field :value_question, String, 'Link ID whos value to autofill if condition is met', null: true
    field :sum_questions, [String], 'Link IDs of numeric questions to sum up and set as the value if condition is met', null: true
    field :formula, String, 'Expression with mathematical or logical function defining the value', null: true

    # Condition specifying when to perform this autofill. If not provided, the autofill will always run.
    # TODO: in future release, make the below fields nullable. For now, setting default_values so that they don't break the frontend, which currently (release-122) expects them to be present.
    field :autofill_behavior, Types::Forms::Enums::EnableBehavior, null: false, default_value: 'ANY'
    field :autofill_when, [Types::Forms::EnableWhen], null: false, default_value: []
    field :autofill_readonly, Boolean, 'Whether to perform autofill when displaying a read-only view (defaults to false)', null: true
  end
end
