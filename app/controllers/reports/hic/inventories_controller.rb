###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::InventoriesController < Hic::BaseController
    def show
      @date = params[:date]&.to_date || params.dig(:report, :date) || Date.current

      @inventories = GrdaWarehouse::Hud::Inventory.joins(:project).
        within_range(@filter.on..@filter.on).
        merge(project_scope).
        distinct
    end
  end
end
