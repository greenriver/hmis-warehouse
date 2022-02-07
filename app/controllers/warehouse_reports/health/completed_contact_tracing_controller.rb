###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class CompletedContactTracingController < ContactTracingController
    def download
      render xlsx: 'download', filename: "Completed Contact Tracing #{Date.current}.xlsx"
    end

    def related_report
      url = url_for(action: :index, only_path: true).sub(%r{^/}, '')
      url.sub!('completed_', '')
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url)
    end

    def load_cases
      @cases = Health::Tracing::Case.completed
    end
  end
end
