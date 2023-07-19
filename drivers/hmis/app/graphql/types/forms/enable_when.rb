###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::EnableWhen < Types::BaseObject
    # Specify show/hide based on whether form is read-only or editable
    field :readonly, Boolean, 'Whether form is being rendered as read-only', null: true

    # Specify show/hide based on dependency to another question or local value

    # Dependent value
    field :question, String, 'The linkId of question that determines whether item is enabled/disabled', null: true
    field :value_local_constant, String, 'Name of local variable that determines whether item is enabled/disabled', null: true

    # Operator
    field :operator, Forms::Enums::EnableOperator, 'How to evaluate the question\'s answer', null: true

    # Comparison value
    field :answer_code, String, 'If question is choice type, value for comparison', null: true
    field :answer_codes, [String], 'If question is choice type, and operator is IN, values for comparison', null: true
    field :answer_group_code, String, 'If question is choice type and has grouped options, value for comparison', null: true
    field :answer_number, Integer, 'If question is numeric, value for comparison', null: true
    field :answer_boolean, Boolean, 'If question is boolean type, value for comparison', null: true
    field :compare_question, String, 'The linkId of a question to compare with the question using the operator', null: true
  end
end
