###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::InventoryBedType < Types::BaseEnum
    graphql_name 'InventoryBedType'

    with_enum_map Hmis::Bed.bed_types_enum_map, prefix_description_with_key: false
  end
end
