###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::ProjectCocsController < Hic::BaseController
    def show
      @project_cocs = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        merge(GrdaWarehouse::Hud::Project.with_hud_project_type(PROJECT_TYPES)).
        distinct

      date = params[:date]&.to_date
      @project_cocs = @project_cocs.merge(GrdaWarehouse::Hud::Project.active_on(date)) if date.present?

      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::ProjectCoc.to_csv(scope: @project_cocs), filename: "projectcoc-#{Time.now}.csv" }
      end
    end
  end
end
