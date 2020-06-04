###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class GeneratorBase
    include ArelHelper

    PENDING = 'pending'
    STARTED = 'started'
    COMPLETED = 'completed'

    def initialize(options)
      @user_id = options[:user_id]
      @start_date = options[:start_date].to_date
      @end_date = options[:end_date].to_date
      @coc_code = options[:coc_code]
      @project_ids = options[:project_ids]
      @options = options.to_h
    end

    def self.find_report(user)
      HudReports::ReportInstance.where(user_id: user.id, report_name: title).last
    end

    def report
      @report ||= HudReports::ReportInstance.create(
        user_id: @user_id,
        coc_code: @coc_code,
        start_date: @start_date,
        end_date: @end_date,
        project_ids: @project_ids,
        state: 'Running',
        options: @options,
        report_name: self.class.title,
        question_names: self.class.questions.keys,
      )
    end

    def run!
      # TODO: Rework to parallelize questions?
      Reporting::RunHudReportJob.perform_later(self.class.name, @options)
    end

    def finish
      @report.update(state: 'Completed')
    end

    def update_state(state)
      @report.update(state: state)
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