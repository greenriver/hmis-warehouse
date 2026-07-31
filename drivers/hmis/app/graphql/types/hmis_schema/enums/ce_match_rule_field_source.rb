###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleFieldSource < Types::BaseEnum
    graphql_name 'CeMatchRuleFieldSource'

    # Client fields, such as current_age
    value 'CLIENT', 'Client'

    # Custom data element fields, such as cde.custom_assessment.my_score.
    # Not using "Custom Assessment" field as the user-facing label,
    # because we will also expose CDEs with other ownership types (e.g. custom field on Client or Enrollment)
    value 'CUSTOM_DATA_ELEMENT', 'Custom'

    # Program Specific Data Elements use "HUD" as their user-facing source label.
    value 'PSDE', 'HUD'

    # Future choices:
    # value 'HOUSEHOLD', 'Household' # e.g. household size, youngest member age, etc.
  end
end
