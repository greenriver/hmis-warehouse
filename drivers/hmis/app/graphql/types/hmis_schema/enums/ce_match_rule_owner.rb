###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeMatchRuleOwner < Types::BaseEnum
    graphql_name 'CeMatchRuleOwner'

    value 'UNIT', 'Unit', value: 'Hmis::Unit'
    value 'UNIT_GROUP', 'Unit Group', value: 'Hmis::UnitGroup'
    value 'PROJECT', 'Project', value: 'Hmis::Hud::Project'
    value 'ORGANIZATION', 'Organization', value: 'Hmis::Hud::Organization'
    value 'DATA_SOURCE', 'Data Source', value: 'GrdaWarehouse::DataSource'
  end
end
