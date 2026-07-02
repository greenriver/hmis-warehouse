###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleType < Types::BaseEnum
    graphql_name 'CeMatchRuleType'

    value 'ELIGIBILITY_REQUIREMENT', 'Eligibility requirement', value: Hmis::Ce::Match::Rule::ELIGIBILITY_REQUIREMENT
    value 'PRIORITY_SCHEME', 'Priority scheme', value: Hmis::Ce::Match::Rule::PRIORITY_SCHEME
  end
end
