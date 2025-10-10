###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class HudListItem < GrdaWarehouseBase
    # Maintains a warehouse copy of HUD reference lists for SQL consumers, including
    # analytics views. Records are refreshed from HudCodeGen JSON by fiscal year to
    # support future HUD releases while keeping historical snapshots.
    # At this time, only 2026 is supported, and it is maintained via a TaskQueue job that only
    # runs once.  In the future, we may want to maintain the list on some cadence, though it
    # should only need to be updated when new HMIS specifications are released.

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
