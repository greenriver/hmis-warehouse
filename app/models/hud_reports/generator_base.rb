###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def self.file_prefix
      "#{short_name} #{fiscal_year}"
    end

    def self.title
      "#{generic_title} - #{fiscal_year}"
    end

    def self.report_year_slug
      fiscal_year.downcase.delete(' ').to_sym
    end

    def queue
      @report.state = 'Waiting'
      @report.question_names = self.class.questions.keys
      @report.save
      Reporting::Hud::RunReportJob.perform_later(self.class.name, @report.id)
    end

    def run!(email: true, manual: true)
      @report.state = 'Waiting'
      @report.question_names = self.class.questions.keys
      @report.manual = manual
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

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @report.project_ids

      scope = scope.merge(@filter.apply(GrdaWarehouse::ServiceHistoryEnrollment.all))

      scope.select(:id)
    end
    memoize :client_scope

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def self.table_descriptions
      {}.tap do |descriptions|
        questions.each_value do |klass|
          descriptions.merge!(klass.table_descriptions)
        end
      end
    end

    def self.describe_table(table_name)
      table_descriptions[table_name]
    end

    def self.column_headings(question)
      question_fields(question).map do |key|
        [key, client_class.detail_headers[key.to_s]]
      end.to_h
    end

    def self.all_extra_fields
      client_class.detail_headers.keys.map(&:to_sym) - common_fields
    end

    # Override in concern per HUD report driver
    # defaults to all questions
    def self.question_fields(_question)
      all_extra_fields
    end

    # Override in concern per HUD report driver
    def self.common_fields
      []
    end

    def self.allowed_options
      [
        :start,
        :end,
        :coc_codes,
        :project_ids,
        :data_source_ids,
        :project_type_codes,
        :project_group_ids,
        :sub_population,
        :age_ranges,
        :hoh_only,
        :genders,
        :races,
        :ethnicities,
      ]
    end
  end
end
