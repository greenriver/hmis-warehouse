###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::FundingSource < Types::BaseEnum
    description 'HUD Funding Source (2.06.1)'
    graphql_name 'FundingSource'

    with_enum_map Hmis::Hud::Funder.funding_source_enum_map
  end
end
