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
    field :answer_code, String, 'Value for question comparison based on operator, if question is string or choice type', null: true
    field :answer_number, String, 'Value for question comparison based on operator, if question is numeric', null: true
    field :answer_boolean, String, 'Value for question comparison based on operator, if question is boolean', null: true
  end
end
