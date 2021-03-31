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
      ClaimsReporting::EngagementReport.max_date_range
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
      ClaimsReporting::EngagementReport.new(enrollment_roster: ClaimsReporting::MemberEnrollmentRoster)
    end

    def calculate
      self.results = {}
      cohorts.each do |population, cohort|
        report = ClaimsReporting::EngagementReport.new(
          enrollment_roster: cohort[:scope],
        )
        results[population] = {
          summary: report.selection_summary,
          detail: report.engagement_rows,
        }
      end
    end

    def cos_rollup(code)
      ClaimsReporting::EngagementReport::COS_ROLLUPS.fetch(code, code)
    end

    def cos_description(code)
      ClaimsReporting::EngagementReport::COS_DESCRIPTIONS.fetch(code, code)
    end

    def claim_date_range
      min = summary(:total_population)[:min_claim_date]
      max = summary(:total_population)[:max_claim_date]
      if min && max
        min.to_date .. max.to_date
      else
        source_report.claim_date_range
      end
    end

    def latest_payment_date
      date = summary(:total_population)[:latest_paid_date]
      if date
        date.to_date
      else
        source_report.latest_payment_date
      end
    end

    def roster_as_of
      claim_date_range.last
    end

    HIGHLIGHT_COS_CATEGORIES = [
      'I-06', # Outpatient ER
      'I-01 BH', # BH Inpatient Behavioral Health
      'P-01', # Office/Home Services
      'P-23', # Case Management
      'P-23', # Case Management
      'P-08', # Behavioral Health
      'I-11', # Nursing - Inpatient
      'P-10', # Nursing - Office
      'P-35', # Other Services'
      'I-08', # Hospital Outpatient Clinic
    ].to_set

    def highlighted_categories
      HIGHLIGHT_COS_CATEGORIES
    end

    def details(cohort)
      results.dig(cohort.to_s, 'detail') || {}.with_indifferent_access
    end

    def summary(cohort)
      (results.dig(cohort.to_s, 'summary')&.to_h || {}).with_indifferent_access
    end

    def result_for(cohort, rollup, category)
      d = details(cohort).detect do |result|
        rollup.to_s == result['cde_cos_rollup'].to_s && category.to_s == result['cde_cos_category'].to_s
      end || {}

      s = summary(cohort)
      # we calculate utilization in terms of n_claims per year per 1000 members
      member_years = if cohort.to_s.starts_with?('engaged_for')
        s['engaged_days'].to_f
      elsif cohort.to_s.starts_with?('pre_engaged')
        s['pre_engagement_days'].to_f
      else
        s['span_mem_days'].to_f
      end / 365

      d['utilization'] = d['n_claims'].to_f / member_years * 1000.0 if member_years.positive?

      d
    end

    def summary_headers
      summary(cohorts.keys.first).keys
    end

    def detail_row_headers
      details(cohorts.keys.first).map do |metric|
        metric.slice('cde_cos_rollup', 'cde_cos_category')
      end
    end

    def cohorts
      {
        pre_engaged: {
          scope: ClaimsReporting::MemberEnrollmentRoster.engaged_for(0..0),
          title: 'Pre-engaged',
        },
        engaged_6_months: {
          scope: ClaimsReporting::MemberEnrollmentRoster.engaged_for(1..182),
          title: 'Engaged <= 6 Months',
        },
        engaged_12_months: {
          scope: ClaimsReporting::MemberEnrollmentRoster.engaged_for(183..365),
          title: 'Engaged 7-12 Months',
        },
        engaged_18_months: {
          scope: ClaimsReporting::MemberEnrollmentRoster.engaged_for(366..547),
          title: 'Engaged 13-18 Months',
        },
        engaged_24_months: {
          scope: ClaimsReporting::MemberEnrollmentRoster.engaged_for(548..730),
          title: 'Engaged 19-24 Months',
        },
        engaged_24_months_or_more: {
          scope: ClaimsReporting::MemberEnrollmentRoster.engaged_for(731..Float::INFINITY),
          title: 'Engaged > 2 years',
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
