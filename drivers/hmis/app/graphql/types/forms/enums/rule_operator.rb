###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::RuleOperator < Types::BaseEnum
    graphql_name 'FormRuleOperator'

    value 'EQUAL'
    value 'NOT_EQUAL'
    value 'INCLUDE'
    value 'NOT_INCLUDE'
    value 'ANY'
    value 'ALL'
  end
end
