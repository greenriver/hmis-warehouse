###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module HudReports
  class GeneratorBase
    include ArelHelper
    include Filter::FilterScopes
    include Rails.application.routes.url_helpers
    extend Memoist

    PENDING = 'pending'.freeze
    STARTED = 'started'.freeze
    COMPLETED = 'completed'.freeze

    attr_reader :report

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

    def run!(email: true)
      @report.state = 'Waiting'
      @report.question_names = self.class.questions.keys
      @report.save
      Reporting::Hud::RunReportJob.perform_now(self.class.name, @report.id, email: email)
    end

    # This selects just ids for the clients, to ensure uniqueness, but uses select instead of pluck
    # so that we can find in batches.
    def client_scope(start_date: @report.start_date, end_date: @report.end_date)
      scope = client_source.
        distinct.
        joins(:service_history_enrollments).
        merge(report_scope_source.open_between(start_date: start_date, end_date: end_date))

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      she_scope = GrdaWarehouse::ServiceHistoryEnrollment.all
      she_scope = filter_for_user_access(she_scope)
      she_scope = filter_for_projects(she_scope)
      she_scope = filter_for_cocs(she_scope)
      she_scope = filter_for_veteran_status(she_scope)
      she_scope = filter_for_household_type(she_scope)
      she_scope = filter_for_head_of_household(she_scope)
      she_scope = filter_for_age(she_scope)
      she_scope = filter_for_gender(she_scope)
      she_scope = filter_for_race(she_scope)
      she_scope = filter_for_ethnicity(she_scope)
      she_scope = filter_for_sub_population(she_scope)
      scope = scope.merge(she_scope)

      scope.select(:id)
    end
    memoize :client_scope

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end
  end
end
