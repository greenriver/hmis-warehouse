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

    # Future choices:
    # value 'PSDE', 'HUD Program Specific Data Element' # or "HUD Assessment", but we will likely include non-assessment-based PSDEs (like move-in date) in the same namepsace
    # value 'HOUSEHOLD', 'Household' # e.g. household size, youngest member age, etc.
  end
end
