###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::ProjectsController < Hic::BaseController
    def show
      @projects = project_scope.joins(:organization).
        distinct

      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Project.to_csv(scope: @projects, override_project_type: true), filename: "project-#{Time.current.to_s(:number)}.csv" }
      end
    end
  end
end
