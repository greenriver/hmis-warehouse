module Reports
  class Hic::ProjectsController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      @projects = GrdaWarehouse::Hud::Project.joins(:organization).
        where(computed_project_type: PROJECT_TYPES).
        distinct 
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Project.to_csv(scope: @projects, override_project_type: true), filename: "project-#{Time.now}.csv" }
      end
    end
  end
end