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

    def initialize(options)
      # Strings for keys because of how the options come back out of the DB
      @user_id = options['user_id']
      @start_date = options['start_date'].to_date
      @end_date = options['end_date'].to_date
      @coc_code = options['coc_code']
      @project_ids = options['project_ids']
      @options = options.to_h
    end

    def self.find_report(user)
      HudReports::ReportInstance.where(user_id: user.id, report_name: title).last || HudReports::ReportInstance.new(user_id: user.id, report_name: title)
    end

    def run!(questions: nil)
      @report = HudReports::ReportInstance.create(
        user_id: @user_id,
        coc_code: @coc_code,
        start_date: @start_date,
        end_date: @end_date,
        project_ids: @project_ids,
        state: 'Waiting',
        options: @options,
        report_name: self.class.title,
        question_names: self.class.questions.keys,
      )
      # TODO: Rework to parallelize questions?
      Reporting::Hud::RunReportJob.perform_later(self.class.name, questions, @report.id)
    end

    def client_scope
      scope = client_source.
        distinct.
        joins(:service_history_enrollments).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.open_between(start_date: @start_date, end_date: @end_date))

      scope = scope.merge(GrdaWarehouse::ServiceHistoryEnrollment.in_coc(coc_code: @coc_code)) if @coc_code
      scope = scope.merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project(@project_ids)) if @project_ids.present?

      scope
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end
  end
end
