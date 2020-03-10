###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudReports
  class GeneratorBase
    attr_accessor :report

    PENDING = 'pending'
    STARTED = 'started'
    COMPLETED = 'completed'

    def initialize(options, report_name)
      puts options
      @user = options[:user]
      @start_date = options[:start_date].to_date
      @end_date = options[:end_date].to_date
      @coc_code = options[:coc_code]
      @options = options

      @report = HudReports::ReportInstance.create(
        user: @user,
        coc_code: @coc_code,
        start_date: @start_date,
        end_date: @end_date,
        state: 'pending',
        options: @options,
        report_name: report_name,
      )
    end

    def update_state(state)
      report.update(state: state)
    end
  end
end