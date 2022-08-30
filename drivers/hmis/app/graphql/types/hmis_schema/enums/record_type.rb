###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::RecordType < Types::BaseEnum
    description 'HUD RecordType (1.4)'
    graphql_name 'RecordType'

    with_enum_map Hmis::Hud::Service.record_type_enum_map
  end
end
