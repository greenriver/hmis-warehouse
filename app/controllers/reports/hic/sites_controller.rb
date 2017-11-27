module Reports
  class Hic::SitesController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      @sites = GrdaWarehouse::Hud::Site.joins(:project).
        where(Project: {computed_project_type: PROJECT_TYPES}).
        distinct 
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Site.to_csv(scope: @sites), filename: "site-#{Time.now}.csv" }
      end
    end
  end
end