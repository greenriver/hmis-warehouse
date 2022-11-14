###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SourceType < Types::BaseEnum
    description '1.9'
    graphql_name 'SourceType'
    value COC_HMIS, '(1) CoC HMIS', value: 1
    value STANDALONE_AGENCY_SPECIFIC_APPLICATION, '(2) Standalone/agency-specific application', value: 2
    value DATA_WAREHOUSE, '(3) Data warehouse', value: 3
    value OTHER, '(4) Other', value: 4
  end
end
