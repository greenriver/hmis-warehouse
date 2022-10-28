###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::EnableWhen < Types::BaseObject
    field :question, String, 'The linkId of question that determines whether item is enabled/disabled', null: false
    field :operator, Forms::Enums::EnableOperator, 'How to evaluate the question\'s answer', null: false
    field :answer_code, String, 'If question is choice type, value for comparison', null: true
    field :answer_codes, [String], 'If question is choice type, and operator is IN, values for comparison', null: true
    field :answer_group_code, String, 'If question is choice type and has grouped options, value for comparison', null: true
    field :answer_number, Integer, 'If question is numeric, value for comparison', null: true
    field :answer_boolean, Boolean, 'If question is boolean type, value for comparison', null: true
  end
end
