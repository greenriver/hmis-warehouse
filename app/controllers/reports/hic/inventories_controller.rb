module Reports
  class Hic::InventoriesController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      it = GrdaWarehouse::Hud::Inventory.arel_table
      @inventories = GrdaWarehouse::Hud::Inventory.joins(:project).
        where(it[:InventoryStartDate].gt((Time.now.beginning_of_year - 1.year).to_date).or(it[:InventoryStartDate].eq(nil))).
        where((pt[:ProjectType].in(PROJECT_TYPES).
          and(pt[:act_as_project_type].eq(nil))).
          or(pt[:act_as_project_type].in(PROJECT_TYPES))).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Inventory.to_csv(scope: @inventories), filename: "inventory-#{Time.now}.csv" }
      end
    end
  end
end