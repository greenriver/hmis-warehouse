###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class HudListItem < GrdaWarehouseBase
    KNOWN_YEARS = ['2026'].freeze

    def self.maintain!
      KNOWN_YEARS.each do |year|
        batch = []
        HudCodeGen.lists_with_method_names(year).each do |list|
          list['values'].each do |item|
            batch << HudListItem.new(
              list_name: list['name'],
              method_name: list['method_name'],
              list_number: list['code'],
              label: item['description'],
              code: item['key'],
              fiscal_year: year,
              active: true,
            )
          end
        end
        # For now, we're just replacing the list on each run
        transaction do
          HudListItem.where(fiscal_year: year).destroy_all
          HudListItem.import batch
        end
      end
    end
  end
end
