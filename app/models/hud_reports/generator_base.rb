###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class GeneratorBase
    include ArelHelper

    attr_reader :report

    PENDING = 'pending'
    STARTED = 'started'
    COMPLETED = 'completed'

    def initialize(options, questions, report_name)
      @user = options[:user]
      @start_date = options[:start_date].to_date
      @end_date = options[:end_date].to_date
      @coc_code = options[:coc_code]
      @project_ids = options[:project_ids]
      @options = options

      @report = HudReports::ReportInstance.create(
        user: @user,
        coc_code: @coc_code,
        start_date: @start_date,
        end_date: @end_date,
        project_ids: @project_ids,
        state: 'pending',
        options: @options,
        report_name: report_name,
        question_names: questions,
      )
    end

    def update_state(state)
      @report.update(state: state)
    end

    def client_scope
      scope = client_source.
        distinct.
        joins(:service_history_enrollments).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.open_between(start_date: @start_date, end_date: @end_date))

      scope = scope.merge(GrdaWarehouse::ServiceHistoryEnrollment.in_coc(@coc_code)) if @coc_code
      scope = scope.merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project(@project_ids)) if @project_ids.present?

      scope
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end
  end
end