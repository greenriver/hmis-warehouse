###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module ClaimsReporting
  class EngagementTrends < HealthBase
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include HmisFilters
    extend Memoist
    acts_as_paranoid

    belongs_to :user, optional: true

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

    def calculate
      self.results = {}
      cohorts.each do |population, cohort|
        report = ClaimsReporting::EngagementReport.new(
          cohort: cohort,
          filter: filter,
        )
        results[population] = {
          summary: report.selection_summary,
          detail: report.engagement_rows,
          sdoh: report.sdoh_rows,
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
      min = results.values.map { |c| c[:min_claim_date]&.to_date }.min || self.class.max_date_range.min
      max = results.values.map { |c| c[:max_claim_date]&.to_date }.max || completed_at.to_date
      min .. max
    end

    def latest_payment_date
      results.values.map { |c| c[:latest_paid_date]&.to_date }.max || completed_at.to_date
    end

    def roster_as_of
      claim_date_range.last
    end

    HIGHLIGHT_COS_CATEGORIES = [
      'I-06', # Outpatient ER
      'I-01 MED', # Inpatient Medical
      'I-01 BH', # BH Inpatient Behavioral Health
      'P-01', # Office/Home Services
      'P-23', # Case Management
      'P-08', # Behavioral Health
      'I-08', # Hospital Outpatient Clinic
      'P-28', # ESP
    ].to_set

    def highlighted_categories
      HIGHLIGHT_COS_CATEGORIES
    end

    def details(cohort)
      results.dig(cohort.to_s, 'detail') || {}.with_indifferent_access
    end

    def summary(cohort)
      (results.dig(cohort.to_s, 'summary')&.to_h || {}).with_indifferent_access.tap do |s|
        member_months = if cohort.to_s.starts_with?('engaged_for')
          s['engaged_days'].to_f
        elsif cohort.to_s.starts_with?('pre_engaged')
          s['pre_engagement_days'].to_f
        else
          s['span_mem_days'].to_f
        end / 30

        paid = s['paid_amount_sum'].to_f

        s[:pmpm] = paid / member_months if paid.positive? && member_months.positive?
      end
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
      {
        'selected_members' => ['Selected Members', :format_i],
        'average_age' => ['Average Age', :format_d],
        # 'n_claims' => ['Medical Claims', :format_i],
        # 'span_mem_days' => ['Enrolled Member Days', :format_i],
        # 'pre_engagement_days' => ['Pre-engaged Member Days', :format_i],
        # 'engaged_days' => ['Engaged Member Days', :format_i],
        # # 'paid_amount_sum' => ['Total Paid', :format_c],
        # 'pmpm' => ['Paid <abbr title="Per member per month">PMPM</abbr>', :format_c],
        'average_raw_dxcg_score' => ['Average MassHealth Risk Score', :format_d],
      }
    end

    def detail_row_headers
      details(cohorts.keys.first).map do |metric|
        metric.slice('cde_cos_rollup', 'cde_cos_category')
      end
    end

    def cohorts
      return engaged_history_cohorts if filter.cohort_type == :engaged_history

      selected_period_cohorts
    end

    private def cohort_scope(engaged_for_days)
      scope = ClaimsReporting::MemberEnrollmentRoster.engaged_for(engaged_for_days)

      # Apply filters via warehouse clients... This is the only place linking this to warehouse_db
      # NOTE: these all expect scope to be something that can be joined to client so we'll
      # use data_source, since everyone has to have one of those
      # They also expect @filter to be set
      @filter = filter
      filtered_by_client = (
        filter.genders.present? ||
        filter.races.present? ||
        filter.ethnicities.present?
      )
      if filtered_by_client
        hmis_scope = ::GrdaWarehouse::Hud::Client.all
        hmis_scope = filter_for_gender(hmis_scope) if filter.genders.present?
        hmis_scope = filter_for_race(hmis_scope) if filter.races.present?
        hmis_scope = filter_for_ethnicity(hmis_scope) if filter.ethnicities.present?
        client_ids = hmis_scope.pluck(c_t[:id])
        scope = scope.joins(:patient).merge(::Health::Patient.where(client_id: client_ids)) if client_ids.any?
      end

      # and via patient referral data
      if filter.acos.present?
        scope = scope.joins(patient: :patient_referral).merge(
          ::Health::PatientReferral.at_acos(filter.acos),
        )
      end

      scope = filter_for_age(scope, as_of: Date.current) if filter.age_ranges.present?

      if filter.food_insecurity.present?
        scope = scope.joins(:patient).merge(
          ::Health::Patient.where(
            id: ::Health::SelfSufficiencyMatrixForm.first_completed.where(
              food_score: (0..filter.food_insecurity.to_i),
            ),
          ),
        )
      end

      scope
    end
    memoize :cohort_scope

    def engaged_history_cohorts
      {
        pre_engaged: {
          scope: cohort_scope(0..0),
          day_range: (0..0),
          title: 'Pre-engaged',
          tooltip: 'Patients not yet engaged.',
        },
        engaged_6_months: {
          scope: cohort_scope(1..182),
          day_range: (1..182),
          title: 'Engaged <= 6 Months',
          tooltip: 'Patients who have fully engaged, and have six or fewer months of time being engaged.',
        },
        engaged_12_months: {
          scope: cohort_scope(183..365),
          day_range: (183..365),
          title: 'Engaged 7-12 Months',
          tooltip: 'Patients who have fully engaged, and have between seven to twelve months of time being engaged.',
        },
        engaged_18_months: {
          scope: cohort_scope(366..547),
          day_range: (366..547),
          title: 'Engaged 13-18 Months',
          tooltip: 'Patients who have fully engaged, and have between thirteen to eighteen months of time being engaged.',
        },
        engaged_24_months: {
          scope: cohort_scope(548..730),
          day_range: (548..730),
          title: 'Engaged 19-24 Months',
          tooltip: 'Patients who have fully engaged, and have between nineteen to twenty four months of time being engaged.',
        },
        engaged_24_months_or_more: {
          scope: cohort_scope(731..Float::INFINITY),
          day_range: (731..Float::INFINITY),
          title: 'Engaged > 2 years',
          tooltip: 'Patients who have fully engaged, and have two years or more of time being engaged.',
        },
      }.freeze
    end
    memoize :engaged_history_cohorts

    def selected_period_cohorts
      {
        pre_engaged: {
          scope: cohort_scope(0..0),
          day_range: (0..0),
          title: 'Pre-engaged',
          tooltip: 'Claims for unengaged patients.',
        },
        engaged_6_months: {
          scope: cohort_scope(1..Float::INFINITY),
          day_range: (1..182),
          title: 'First 6 Months of Engagement',
          tooltip: 'Claims occurring during the first six months of engagement.',
        },
        engaged_12_months: {
          scope: cohort_scope(183..Float::INFINITY),
          day_range: (183..365),
          title: '7-12 Months of Engagement',
          tooltip: 'Claims occurring during six to twelve months of engagement.',
        },
        engaged_18_months: {
          scope: cohort_scope(366..Float::INFINITY),
          day_range: (366..547),
          title: '13-18 Months of Engagement',
          tooltip: 'Claims occurring during thirteen to eighteen months of engagement.',
        },
        engaged_24_months: {
          scope: cohort_scope(548..Float::INFINITY),
          day_range: (548..730),
          title: '19-24 Months of Engagement',
          tooltip: 'Claims occurring during nineteen months to two years of engagement.',
        },
        engaged_24_months_or_more: {
          scope: cohort_scope(731..Float::INFINITY),
          day_range: (731..Float::INFINITY),
          title: '2+ years of Engagement',
          tooltip: 'Claims occurring after two years of engagement.',
        },
      }.freeze
    end
    memoize :selected_period_cohorts

    # def filter=(filter_object)
    #   self.options = filter_object.for_params
    #   # force reset the filter cache
    #   @filter = nil
    #   filter
    # end

    def filter
      @filter ||= begin
        f = ::Filters::EngagementFilter.new(user_id: user_id)
        f.set_from_params(options.with_indifferent_access)
        f
      end
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'claims_reporting/warehouse_reports/engagement_trends'
    end

    def url
      claims_reporting_warehouse_reports_engagement_trends_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
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

    def self.sdoh_categories
      {
        'Race' => {
          race_am_ind_ak_native: 'American Indian or Alaska Native',
          race_asian: 'Asian',
          race_black_af_american: 'Black or African American',
          race_native_hi_other_pacific: 'Native Hawaiian or Other Pacific Islander',
          race_white: 'White',
          multi_racial: 'Multi-Racial',
        },
        'Ethnicity' => {
          ethnicity_non_hispanic_non_latino: 'Non-Hispanic/Non-Latino',
          ethnicity_hispanic_latino: 'Hispanic/Latino',
        },
        'Primary Language' => {
          '1. English' => '1. English',
          '2. Spanish' => '2. Spanish',
          '3. French' => '3. French',
          '4. Other' => '4. Other',
        },
        'Gender' => {
          gender_female: 'Female',
          gender_male: 'Male',
          gender_mtf: 'Trans Female (MTF or Male to Female)',
          gender_ftm: 'Trans Male (FTM or Female to Male)',
          no_single_gender: 'No Single Gender',
        },
        'Housing Status' => {
          'Housed at start' => 'Housed at start',
          'Homeless at start' => 'Homeless at start',
          'Housed at end' => 'Housed at end',
          'Homeless at end' => 'Homeless at end',
          'Ever homeless' => 'Ever homeless',
        },
        'SSM (average initial scores)' => ::Health::SelfSufficiencyMatrixForm::SSM_QUESTION_TITLE,
      }
    end
  end
end
