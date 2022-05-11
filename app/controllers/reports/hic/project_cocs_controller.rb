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
    end
  end
end
