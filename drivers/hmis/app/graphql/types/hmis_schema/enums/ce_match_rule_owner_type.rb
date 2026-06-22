###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleOwnerType < Types::BaseEnum
    graphql_name 'CeMatchRuleOwnerType'

    value 'UNIT_GROUP', 'Unit Group', value: 'Hmis::UnitGroup'
    value 'PROJECT', 'Project', value: 'Hmis::Hud::Project'
    value 'ORGANIZATION', 'Organization', value: 'Hmis::Hud::Organization'
    # For clarity, the human-readable label for data-source-owned rules is "Global"
    value 'DATA_SOURCE', 'Global', value: 'GrdaWarehouse::DataSource'
  end
end
