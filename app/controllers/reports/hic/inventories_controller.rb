###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports
  class Hic::InventoriesController < Hic::BaseController
    def show
      @inventories = GrdaWarehouse::Hud::Inventory.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        merge(GrdaWarehouse::Hud::Project.with_hud_project_type(PROJECT_TYPES)).
        where(
          i_t[:InventoryStartDate].gt((Time.now.beginning_of_year - 1.year).to_date).or(i_t[:InventoryStartDate].eq(nil)),
        ).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Inventory.to_csv(scope: @inventories), filename: "inventory-#{Time.now}.csv" }
      end
    end
  end
end
