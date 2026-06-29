###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleFieldSource < Types::BaseEnum
    graphql_name 'CeMatchRuleFieldSource'

    value 'CLIENT', description: 'A client field, such as current_age'
    value 'CUSTOM_DATA_ELEMENT', description: 'A custom data element, such as cde.custom_assessment.my_score'
  end
end
