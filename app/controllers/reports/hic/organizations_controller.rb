module Reports
  class Hic::OrganizationsController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      @organizations = organization_scope.joins(:projects).
        where(computed_project_type: PROJECT_TYPES).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Organization.to_csv(scope: @organizations), filename: "organization-#{Time.now}.csv" }
      end
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization.viewable_by current_user
    end
  end
end