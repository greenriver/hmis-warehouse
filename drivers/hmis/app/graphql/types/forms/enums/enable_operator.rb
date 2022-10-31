###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::EnableOperator < Types::BaseEnum
    graphql_name 'EnableOperator'

    value 'EXISTS'
    value 'NOT_EXISTS'
    value 'EQUAL'
    value 'NOT_EQUAL'
    value 'GREATER_THAN'
    value 'LESS_THAN'
    value 'GREATER_THAN_EQUAL'
    value 'LESS_THAN_EQUAL'
  end
end
