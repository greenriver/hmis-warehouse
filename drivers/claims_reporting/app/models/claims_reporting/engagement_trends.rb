###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting
  class EngagementTrends < HealthBase
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ArelHelper
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

    # The maximum possible date range
    # where we have claims data
    def self.max_date_range
      ClaimsReporting::MedicalClaim.minimum(:service_start_date) .. ClaimsReporting::MedicalClaim.maximum(:service_start_date)
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

    def source_report
      ClaimsReporting::EngagementReport.new(claim_date_range: options['start_date'].to_date..options['end_date'].to_date)
    end

    def calculate
      self.results = {}
      cohorts.each do |population, cohort|
        report = ClaimsReporting::EngagementReport.new(
          member_roster: cohort[:scope],
          claim_date_range: options['start_date'].to_date..options['end_date'].to_date,
        )
        results[population] = report.engagement_rows
      end
    end

    def result_for(cohort, rollup, category)
      results[cohort.to_s].detect do |result|
        rollup.to_s == result['cde_cos_rollup'].to_s && category.to_s == result['cde_cos_category'].to_s
      end || {}
    end

    def detail_row_headers
      results['total_population'].map do |metric|
        metric.slice('cde_cos_rollup', 'cde_cos_category')
      end
    end

    def cohorts
      {
        total_population: {
          scope: ClaimsReporting::MemberRoster.distinct,
          title: 'Total Population',
        },
        pre_assigned: {
          scope: ClaimsReporting::MemberRoster.pre_assigned,
          title: 'Not Enrolled',
        },
        pre_engaged: {
          scope: ClaimsReporting::MemberRoster.pre_engaged,
          title: 'Assigned-Not-Engaged',
        },
        engaged_6_months: {
          scope: ClaimsReporting::MemberRoster.engaged_for(1..180),
          title: 'Engaged 0-6 Months',
        },
        engaged_12_months: {
          scope: ClaimsReporting::MemberRoster.engaged_for(181..365),
          title: 'Engaged 7-12 Months',
        },
        engaged_24_months: {
          scope: ClaimsReporting::MemberRoster.engaged_for(366..545),
          title: 'Engaged 1-2 Years',
        },
        engaged_24_months_or_more: {
          scope: ClaimsReporting::MemberRoster.engaged_for(546..10_000),
          title: 'Engaged 2+ years',
        },
      }.freeze
    end

    # def filter=(filter_object)
    #   self.options = filter_object.for_params
    #   # force reset the filter cache
    #   @filter = nil
    #   filter
    # end

    # def filter
    #   @filter ||= begin
    #     f = ::Filters::FilterBase.new(user_id: user_id)
    #     f.set_from_params(options['filters'].with_indifferent_access) if options.try(:[], 'filters')
    #     f
    #   end
    # end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'claims_reporting/warehouse_reports/engagement_trends'
    end

    def url
      claims_reporting_warehouse_reports_engagement_trends_url(host: ENV.fetch('FQDN'), id: id)
    end

    def title
      _('Patient Engagement Trends')
    end

    def report_path_array
      [
        :claims_reporting,
        :warehouse_reports,
        :engagement_trends,
      ]
    end
  end
end
