###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::SitesController < Hic::BaseController
    def show
      # NOTE No longer included post 2020
      @sites = GrdaWarehouse::Hud::Geography.joins(:project).
        merge(project_scope).
        distinct
    end
  end
end
