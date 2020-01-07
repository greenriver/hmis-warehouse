###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports
  class Hic::ProjectsController < Hic::BaseController
    def show
      @projects = GrdaWarehouse::Hud::Project.joins(:organization).
        viewable_by(current_user).
        with_hud_project_type(PROJECT_TYPES).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Project.to_csv(scope: @projects, override_project_type: true), filename: "project-#{Time.now}.csv" }
      end
    end
  end
end
