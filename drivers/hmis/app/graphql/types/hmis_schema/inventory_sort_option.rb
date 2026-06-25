###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::InventorySortOption < Types::BaseEnum
    description 'HUD Inventory Sorting Options'
    graphql_name 'InventorySortOption'

    Hmis::Hud::Inventory::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt
    end
  end
end
