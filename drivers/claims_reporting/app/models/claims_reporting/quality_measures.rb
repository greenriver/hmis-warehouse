###
###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class QualityMeasures < HealthBase
    include Reporting::Status

    # include ArelHelper
    #  include ::Filter::FilterScopes
    acts_as_paranoid

    belongs_to :user, optional: true

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(created_at: :desc)
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    # API FOR ::WarehouseReports::GenericReportJob
    def title
      _('CP Quality Measures')
    end

    # API FOR ::WarehouseReports::GenericReportJob
    def self.url
      'claims_reporting/warehouse_reports/quality_measures'
    end

    # API FOR ::WarehouseReports::GenericReportJob
    def run_and_save!
      update_columns(started_at: Time.current)

      calculate
      assign_attributes(completed_at: Time.current)
      save!
    rescue Exception => e
      assign_attributes(failed_at: Time.current, processing_errors: [e.message, e.backtrace].to_json)
      save!
      raise e
    end

    include Rails.application.routes.url_helpers

    def url
      claims_reporting_warehouse_reports_quality_measure_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def path
      claims_reporting_warehouse_reports_quality_measure_path(id: to_param)
    end

    def filter
      @filter ||= begin
        f = ::Filters::QualityMeasuresFilter.new(user_id: user_id)
        f.set_from_params((options || {}).with_indifferent_access)
        f
      end
    end

    def report_path_array
      [
        :claims_reporting,
        :warehouse_reports,
        :quality_measures,
      ]
    end

    def available_filters
      []
    end

    def self.available_years
      # we want the last full year of claims data which is not available until 3 months into the following year
      (2018 .. (Date.current << 15).year).map(&:to_s)
    end

    def self.latest!(user:, option: {})
      options = {
        years: available_years,
      }.merge(option)

      existing_report = where(
        ['options = ?::jsonb', options.to_json],
      ).order(completed_at: :desc).first
      return existing_report if existing_report

      new_report = create!(
        user_id: user.id,
        options: options,
        results: {},
      )
      ::WarehouseReports::GenericReportJob.perform_now(
        user_id: new_report.user_id,
        report_class: name,
        report_id: new_report.id,
      )
      new_report
    end

    def measure_value(year, measure)
      (results&.dig(year.to_s, 'measures', measure.to_s) || {}).with_indifferent_access
    end

    def years
      options['years'] || self.class.available_years
    end

    def calculate
      self.results ||= {}
      # run annual report for each selected plan_year, saving as we go if possible

      years.each do |year|
        self.results[year] = ClaimsReporting::QualityMeasuresReport.for_plan_year(
          year.to_s,
          filter: filter,
        ).serializable_hash
        save unless new_record?
      end
    end
  end
end
