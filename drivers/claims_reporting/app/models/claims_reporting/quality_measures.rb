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

    belongs_to :user

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
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
      # rescue Exception => e
      #   assign_attributes(failed_at: Time.current, processing_errors: [e.message, e.backtrace].to_json)
      #   save
      #   raise e
    end

    include Rails.application.routes.url_helpers
    def url
      claims_reporting_warehouse_reports_quality_measure_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
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

    def self.for_plan_year(year, user:, report_params: {})
      raise 'TODO' unless report_params == {}

      options = report_params.merge('year' => year)

      existing_report = where(
        ['options = ?::jsonb', options.to_json],
      ).order(completed_at: :desc).first
      return existing_report if existing_report

      new_report = create!(
        user_id: user.id,
        options: options,
      )

      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: new_report.user_id,
        report_class: name,
        report_id: new_report.id,
      )
      new_report
    end

    def measure_value(measure)
      info = results.dig('measures', measure.to_s) if results

      info || {}
    end

    def calculate
      self.results = ClaimsReporting::QualityMeasuresReport.for_plan_year(
        options['year'],
      ).serializable_hash
    end
  end
end
