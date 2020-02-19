###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports
  class Hic::FundersController < Hic::BaseController
    def show
      @funders = funder_scope.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        merge(GrdaWarehouse::Hud::Project.with_hud_project_type(PROJECT_TYPES)).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Funder.to_csv(scope: @funders), filename: "funder-#{Time.now}.csv" }
      end
    end

    def funder_scope
      GrdaWarehouse::Hud::Funder
    end
  end
end
