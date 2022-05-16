###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport::WarehouseReports
  class ReportController < ApplicationController
    include WarehouseReportAuthorization

    def index
    end
  end
end
