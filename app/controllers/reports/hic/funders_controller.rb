###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reports
  class Hic::FundersController < Hic::BaseController
    def show
      @funders = funder_scope.joins(:project).
        merge(project_scope).
        distinct
    end

    def funder_scope
      GrdaWarehouse::Hud::Funder
    end
  end
end
