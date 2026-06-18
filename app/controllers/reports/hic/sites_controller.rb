###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
