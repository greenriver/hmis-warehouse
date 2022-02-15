###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::ProjectCocsController < Hic::BaseController
    def show
      @project_cocs = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
        merge(project_scope).
        distinct

      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::ProjectCoc.to_csv(scope: @project_cocs), filename: "projectcoc-#{Time.current.to_s(:number)}.csv" }
      end
    end
  end
end
