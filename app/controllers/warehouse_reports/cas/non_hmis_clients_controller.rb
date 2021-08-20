###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class NonHmisClientsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      @report = ::Cas::NonHmisClient.find_matches(report_source)
    end

    def report_source
      ::Cas::NonHmisClient.unassigned
    end
  end
end
