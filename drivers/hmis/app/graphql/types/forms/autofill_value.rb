###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::AutofillValue < Types::BaseObject
    description 'Value to autofill based on conditional logic'

    field :value_code, String, 'If question is choice type, autofill value', null: true
    field :value_number, Integer, 'If question is numeric, autofill value', null: true
    field :value_boolean, Boolean, 'If question is boolean type, autofill value', null: true
    field :value_question, String, 'Link ID of question to autofill value from', null: true
    field :autofill_behavior, Types::Forms::Enums::EnableBehavior, null: false
    field :autofill_when, [Types::Forms::EnableWhen], null: false
  end
end
