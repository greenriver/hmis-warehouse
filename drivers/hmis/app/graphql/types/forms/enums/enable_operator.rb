###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::EnableOperator < Types::BaseEnum
    graphql_name 'EnableOperator'

    value 'ENABLED', 'Use with answerBoolean to specify is the item should be enabled or not.'
    value 'EXISTS', 'Use with answerBoolean to specify if an answer should exist or not.'
    value 'IN', 'Whether the value is in the answerCodes array.'
    value 'EQUAL'
    value 'NOT_EQUAL'
    value 'GREATER_THAN'
    value 'LESS_THAN'
    value 'GREATER_THAN_EQUAL'
    value 'LESS_THAN_EQUAL'
  end
end
