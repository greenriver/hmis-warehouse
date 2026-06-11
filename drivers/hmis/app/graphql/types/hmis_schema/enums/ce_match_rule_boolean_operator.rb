###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleBooleanOperator < Types::BaseEnum
    graphql_name 'CeMatchRuleBooleanOperator'

    value 'AND'
    value 'OR'
  end
end
