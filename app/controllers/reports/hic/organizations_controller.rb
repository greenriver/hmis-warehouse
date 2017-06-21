module Reports
  class Hic::OrganizationsController < Hic::BaseController

    def show
      pt = GrdaWarehouse::Hud::Project.arel_table
      @organizations = organization_scope.joins(:projects).
        where((pt[:ProjectType].in(PROJECT_TYPES).
          and(pt[:act_as_project_type].eq(nil))).
          or(pt[:act_as_project_type].in(PROJECT_TYPES))).
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