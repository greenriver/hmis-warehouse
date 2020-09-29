###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class GeneratorBase
    include ArelHelper

    PENDING = 'pending'.freeze
    STARTED = 'started'.freeze
    COMPLETED = 'completed'.freeze

    # Takes a report instance (usually unsaved)
    def initialize(report)
      @report = report
    end

    def self.find_report(user)
      HudReports::ReportInstance.where(user_id: user.id, report_name: title).last || HudReports::ReportInstance.new(user_id: user.id, report_name: title)
    end

    def queue
      @report.state = 'Waiting'
      @report.question_names = self.class.questions.keys
      @report.save
      Reporting::Hud::RunReportJob.perform_later(self.class.name, @report.id)
    end

    def client_scope
      scope = client_source.
        distinct.
        joins(:service_history_enrollments).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.open_between(start_date: @report.start_date, end_date: @report.end_date))

      scope = scope.merge(GrdaWarehouse::ServiceHistoryEnrollment.in_coc(coc_code: @report.coc_code)) if @report.coc_code
      scope = scope.merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project(@report.project_ids)) if @report.project_ids.present?

      scope
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end
  end
end
