###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::InventoriesController < Hic::BaseController
    def show
      @date = params[:date]&.to_date || params.dig(:report, :date) || Date.current

      @inventories = GrdaWarehouse::Hud::Inventory.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        merge(GrdaWarehouse::Hud::Project.with_hud_project_type(PROJECT_TYPES)).
        distinct

      if @date.present?
        @inventories = @inventories.merge(GrdaWarehouse::Hud::Inventory.within_range(@date..@date))
        @inventories = @inventories.merge(GrdaWarehouse::Hud::Project.active_on(@date))
      end

      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Inventory.to_csv(scope: @inventories), filename: "inventory-#{Time.current}.csv" }
      end
    end
  end
end
