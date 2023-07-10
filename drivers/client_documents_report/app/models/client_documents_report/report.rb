###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDocumentsReport
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_accessor :filter

    def initialize(filter)
      @filter = filter
    end

    def self.url
      'client_documents_report/warehouse_reports/reports'
    end

    def include_comparison?
      false
    end

    def report_path_array
      [
        :client_documents_report,
        :warehouse_reports,
        :reports,
      ]
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def multiple_project_types?
      true
    end

    def filter_path_array
      [:filters] + report_path_array
    end
  end
end
