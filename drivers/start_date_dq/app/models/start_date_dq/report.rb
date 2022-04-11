###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StartDateDq
  class Report
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include Filter::FilterScopes

    attr_reader :filter

    def initialize(user_id, filter = nil)
      @filter = filter || default_filter(user_id)
    end

    def default_filter(user_id)
      Filters::FilterBase.new(user_id: user_id, start: '2018-01-01')
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'start_date_dq/warehouse_reports/reports'
    end

    def title
      'Approximate Start Date Data Quality'
    end

    def data
      report_scope.joins(:client, :project).
        where(e_t[:EntryDate].not_eq(nil).
          and(e_t[:DateToStreetESSH].not_eq(nil))).
        order(datediff(report_scope, 'day', e_t[:EntryDate], e_t[:DateToStreetESSH]).desc)
    end

    def report_scope
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_project_type(scope, all_project_types: false)
      scope = filter_for_projects(scope)
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:enrollment)
    end
  end
end
