###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleComparator < Types::BaseEnum
    graphql_name 'CeMatchRuleComparator'

    value 'EQ'
    value 'NOT_EQ'
    value 'LT'
    value 'LTE'
    value 'GT'
    value 'GTE'
    value 'INCLUDES'
    value 'EXCLUDES'
  end
end
