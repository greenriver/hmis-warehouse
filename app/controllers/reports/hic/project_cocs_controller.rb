###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reports
  class Hic::ProjectCocsController < Hic::BaseController
    def show
      @project_cocs = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
        merge(project_scope).
        distinct
    end
  end
end
