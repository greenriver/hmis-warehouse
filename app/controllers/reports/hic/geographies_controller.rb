###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports
  class Hic::GeographiesController < Hic::BaseController
    def show
      @geographies = GrdaWarehouse::Hud::Geography.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        merge(GrdaWarehouse::Hud::Project.with_hud_project_type(PROJECT_TYPES)).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Geography.to_csv(scope: @geographies), filename: "geography-#{Time.now}.csv" }
      end
    end
  end
end
