module Reports
  class Hic::OrganizationsController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      @organizations = GrdaWarehouse::Hud::Organization.joins(:projects).
        where((pt[:ProjectType].in(PROJECT_TYPES).
          and(pt[:act_as_project_type].eq(nil))).
          or(pt[:act_as_project_type].in(PROJECT_TYPES))).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Organization.to_csv(scope: @organizations), filename: "organization-#{Time.now}.csv" }
      end
    end
  end
end