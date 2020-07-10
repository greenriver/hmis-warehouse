###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::GeographiesController < Hic::BaseController
    def show
      @geographies = GrdaWarehouse::Hud::Geography.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        merge(GrdaWarehouse::Hud::Project.with_hud_project_type(PROJECT_TYPES)).
        distinct

      date = params[:date]&.to_date
      @geographies = @geographies.merge(GrdaWarehouse::Hud::Project.active_on(date)) if date.present?

      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Geography.to_csv(scope: @geographies), filename: "geography-#{Time.now}.csv" }
      end
    end
  end
end
