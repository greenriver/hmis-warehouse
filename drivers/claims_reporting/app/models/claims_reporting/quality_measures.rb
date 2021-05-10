###
###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class QualityMeasures < HealthBase
    include Reporting::Status
    include Rails.application.routes.url_helpers
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

    def self.url
      'claims_reporting/warehouse_reports/quality_measures'
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

    def url
      claims_reporting_warehouse_reports_quality_measuures_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('CP Quality Measures')
    end

    def run_and_save!
      update(started_at: Time.current)
      begin
        calculate
        assign_attributes(completed_at: Time.current)
        save
      rescue Exception => e
        assign_attributes(failed_at: Time.current, processing_errors: [e.message, e.backtrace].to_json)
        save
        raise e
      end
    end

    def calculate
      self.results = ClaimsReporting::QualityMeasuresReport.for_plan_year(options.delete(:year))
    end
  end
end
