module Reports
  class Hic::ProjectsController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      @projects = GrdaWarehouse::Hud::Project.joins(:organization).
        where((pt[:ProjectType].in(PROJECT_TYPES).
          and(pt[:act_as_project_type].eq(nil))).
          or(pt[:act_as_project_type].in(PROJECT_TYPES))).
        distinct 
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Project.to_csv(scope: @projects, override_project_type: true), filename: "project-#{Time.now}.csv" }
      end
    end
  end
end