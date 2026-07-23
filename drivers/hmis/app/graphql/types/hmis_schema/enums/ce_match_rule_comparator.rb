###
# Copyright Green River Data Group, Inc.
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
    value 'IS_NULL'
    value 'IS_NOT_NULL'
  end
end
