###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::FundersController < Hic::BaseController
    def show
      @funders = funder_scope.joins(:project).
        merge(project_scope).
        distinct

      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Funder.to_csv(scope: @funders), filename: "funder-#{Time.current.to_s(:number)}.csv" }
      end
    end

    def funder_scope
      GrdaWarehouse::Hud::Funder
    end
  end
end
