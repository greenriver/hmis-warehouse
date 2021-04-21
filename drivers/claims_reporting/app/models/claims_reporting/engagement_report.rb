###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memoist'
module ClaimsReporting
  class EngagementReport
    include ActiveModel::Model
    include ArelHelper
    extend Memoist
    attr_reader :member_roster, :enrollment_roster, :medical_claims, :rx_claims, :claim_date_range

    DAYS_PER_YEAR = 365.2422

    # The maximum possible date range
    # where we have claims data
    def self.max_date_range
      start_date = ClaimsReporting::MedicalClaim.minimum(:service_start_date)

      # 2012 is roughly when CoCs became a funded
      return Date.iso8601('2012-10-01')..Date.current unless start_date.present?

      start_date .. ClaimsReporting::MedicalClaim.maximum(:service_start_date)
    end

    def initialize(cohort: nil, filter: nil)
      cohort ||= { scope: ClaimsReporting::MemberEnrollmentRoster.all }
      filter ||= ::Filters::ClaimsFilter.new

      raise ArgumentError, 'cohort[:scope] must contain a ClaimsReporting::MemberEnrollmentRoster scope' unless cohort[:scope].model.name == 'ClaimsReporting::MemberEnrollmentRoster'
      raise ArgumentError, 'filter must be a ::Filters::ClaimsFilter' unless filter.is_a? ::Filters::ClaimsFilter

      @filter = filter

      @enrollment_roster = cohort[:scope]

      @member_roster = ClaimsReporting::MemberRoster.where(member_id: @enrollment_roster.select(:member_id))

      @medical_claims = ClaimsReporting::MedicalClaim.joins(:member_roster).merge(@member_roster)

      @claim_date_range = (@medical_claims.minimum(:service_start_date) || self.class.max_date_range.min) .. (
           @medical_claims.maximum(:service_start_date) || self.class.max_date_range.max)

      @rx_claims = ClaimsReporting::RxClaim.none # TBD
    end

    def roster_as_of
      claim_date_range.last
    end

    def report_days
      (claim_date_range.last.to_date - claim_date_range.first.to_date).to_i
    end

    def report_years
      report_days / DAYS_PER_YEAR
    end

    def latest_payment_date
      [medical_claims.maximum(:paid_date), rx_claims.maximum(:paid_date)].compact.max
    end

    def member_totals
      connection.select_one(member_roster.select(
                              mrt[:member_id].count(true).as('total_members'),
                            ), 'member_totals').with_indifferent_access
    end
    memoize :member_totals

    private def member_summary
      connection.select_one(selected_member_roster.select(
                              mrt[:member_id].count(true).as('selected_members'),
                              Arel.sql(%[SUM(CASE WHEN sex = 'Female' THEN 1 ELSE 0 END)]).as('selected_females'),
                              Arel.sql(%[AVG(ABS(EXTRACT(YEAR FROM AGE(date_of_birth, #{connection.quote roster_as_of}))))]).as('average_age'),
                              Arel.sql(%[AVG(NULLIF(raw_dxcg_risk_score,'')::numeric)]).as('average_raw_dxcg_score'),
                            ), 'member_summary')
    end

    private def enrollment_summary
      connection.select_one(selected_enrollments.select(
                              Arel.sql(%[SUM(span_mem_days)]).as('span_mem_days'),
                              Arel.sql(%[SUM(pre_engagement_days)]).as('pre_engagement_days'),
                              Arel.sql(%[SUM(engaged_days)]).as('engaged_days'),
                            ), 'enrollment_summary')
    end

    private def claims_summary
      connection.select_one(selected_medical_claims.select(
                              Arel.sql(%[MAX(paid_date)]).as('latest_paid_date'),
                              paid_amount_sum,
                              n_claims,
                              Arel.sql(%[COUNT(*)]).as('medical_claim_lines'),
                            ), 'claims_summary')
    end

    def selection_summary
      ActiveSupport::HashWithIndifferentAccess.new(
        min_claim_date: claim_date_range.min,
        max_claim_date: claim_date_range.max,
      ).merge(
        member_summary,
      ).merge(
        enrollment_summary,
      ).merge(
        claims_summary,
      )
    end
    memoize :selection_summary

    def total_members
      member_totals[:total_members]
    end

    def selected_members
      selection_summary[:selected_members]
    end

    def percent_members_selected
      return 0 unless total_members&.positive?

      selected_members * 100.0 / total_members
    end

    def member_months
      days = selection_summary[:span_mem_days]
      return unless days

      days / 30
    end

    def average_per_member_per_month_spend
      paid_amount = selection_summary[:paid_amount_sum]

      return unless paid_amount && member_months && member_months.positive?

      paid_amount.to_d / member_months
    end

    def average_raw_dxcg_score
      selection_summary[:average_raw_dxcg_score]&.to_d
    end

    def average_age
      selection_summary[:average_age]&.to_d
    end

    def pct_female
      return unless selected_members&.positive?

      (selection_summary[:selected_females].to_d * 100.0 / selected_members)
    end

    private def formatter
      ClaimsReporting::Formatter.new
    end
    memoize :formatter

    def formatted_value(fld, row)
      val = row[fld.to_s]
      if val.blank?
        val
      elsif fld.in?([:paid_amount_sum, :avg_cost_per_service, :cohort_per_member_month_spend])
        formatter.number_to_currency val
      elsif fld.to_s =~ /pct_of/
        formatter.format_pct val, precision: 2
      elsif (number = begin
                      val.to_d
                    rescue StandardError
                      nil
                    end)
        formatter.format_d number, precision: 2
      else
        val
      end
    end

    def summary_rows
      [
        ['Members', formatter.format_i(selected_members)],
        ['Average Age', formatter.format_d(average_age)],
        ['% Female', formatter.format_pct(pct_female)],
        ['Member Months', formatter.format_d(member_months)],
        ['Average MassHealth Risk Score', formatter.format_d(average_raw_dxcg_score)],
        ['Average $PMPM', formatter.number_to_currency(average_per_member_per_month_spend)],
      ]
    end

    private def mrt
      member_roster.arel_table
    end

    private def mct
      medical_claims.arel_table
    end

    private def n_claims
      Arel.sql(%[COUNT(DISTINCT claim_number)]).as('n_claims')
    end

    private def n_members
      mrt[:member_id].count(true).as('n_members')
    end

    private def paid_amount_sum
      Arel.sql(%[SUM(COALESCE(paid_amount, 0))]).as('paid_amount_sum')
    end

    private def claims_query
      # n_admits = Arel.sql(%[
      #   NULLIF(
      #     COUNT(DISTINCT
      #       CASE WHEN admit_date IS NOT NULL THEN CONCAT(#{sql_member_id}, admit_date) END
      #     ), 0
      #   )
      # ]).as('admit_date')

      # avg_length_of_stay = Arel.sql("ROUND(AVG(
      #   CASE
      #     WHEN discharge_date-admit_date < #{engagement_span.min} THEN NULL
      #     WHEN discharge_date-admit_date > #{engagement_span.max} THEN NULL
      #     ELSE discharge_date-admit_date
      #   END
      # ))").as('avg_length_of_stay')

      selected_medical_claims.group(
        Arel.sql(%[ROLLUP(1,2)]),
      ).select(
        Arel.sql(%[COALESCE(cde_cos_rollup,'Unclassified')]).as('cde_cos_rollup'),
        Arel.sql(%[COALESCE(cde_cos_category,'Unclassified')]).as('cde_cos_category'),
        n_members,
        n_claims,
        paid_amount_sum,
      ).order('1 ASC NULLS FIRST,2 ASC NULLS FIRST')
    end

    def engagement_span
      # from the Milliman prototype -- mix max stay in days
      0 .. 9_999
    end

    private def connection
      HealthBase.connection
    end

    def engagement_rows
      return [] unless selected_members&.positive? && report_years.positive?

      connection.select_all claims_query
    end

    def sdoh_rows
      {
        'Race' => race_rows,
        'Ethnicity' => ethnicity_rows,
        'Primary Language' => primary_language_rows,
        'Gender' => gender_rows,
        'Housing Status' => housing_status_rows,
        'SSM (average initial scores)' => ssm_rows,
      }
    end

    def client_ids
      @client_ids ||= member_roster.joins(:patient).distinct.pluck(:client_id)
    end

    def patient_ids
      @patient_ids ||= member_roster.joins(:patient).select(hp_t[:id])
    end

    def race_rows
      {
        race_am_ind_ak_native: 'American Indian or Alaska Native',
        race_asian: 'Asian',
        race_black_af_american: 'Black or African American',
        race_native_hi_other_pacific: 'Native Hawaiian or Other Pacific Islander',
        race_white: 'White',
        multi_racial: 'Multi-Racial',
      }.map do |race_scope, name|
        [
          name,
          GrdaWarehouse::Hud::Client.where(id: client_ids).send(race_scope).count,
        ]
      end.to_h
    end

    def ethnicity_rows
      {
        ethnicity_non_hispanic_non_latino: 'Non-Hispanic/Non-Latino',
        ethnicity_hispanic_latino: 'Hispanic/Latino',
      }.map do |ethnicity_scope, name|
        [
          name,
          GrdaWarehouse::Hud::Client.where(id: client_ids).send(ethnicity_scope).count,
        ]
      end.to_h
    end

    def primary_language_rows
      languages = {
        '1. English' => 0,
        '2. Spanish' => 0,
        '3. French' => 0,
        '4. Other' => 0,
      }
      patients = Set.new
      ::Health::ComprehensiveHealthAssessment.latest_completed.where(patient_id: patient_ids).find_each do |cha|
        language = cha.answer(:b_q3)
        next if language.blank?

        languages[language] ||= 0
        languages[language] += 1 unless patients.include?(cha.patient_id)
        patients << cha.patient_id
      end
      languages
    end

    def housing_status_rows
      housing_situations = {
        'Housed at start' => 0,
        'Homeless at start' => 0,
        'Housed at end' => 0,
        'Homeless at end' => 0,
        'Ever homeless' => 0,
      }
      GrdaWarehouse::Hud::Client.where(id: client_ids).find_each do |client|
        stati = client.health_housing_stati
        next unless stati.present?

        housing_situations['Housed at start'] += 1 if stati.first[:score] >= 4
        housing_situations['Homeless at start'] += 1 if stati.first[:score] < 4
        housing_situations['Housed at end'] += 1 if stati.last[:score] >= 4
        housing_situations['Homeless at end'] += 1 if stati.last[:score] < 4
        housing_situations['Ever homeless'] += 1 if stati.map { |s| s[:score] }.any? { |s| s < 4 }
      end
      housing_situations
    end

    def gender_rows
      {
        gender_female: 'Female',
        gender_male: 'Male',
        gender_mtf: 'Trans Female (MTF or Male to Female)',
        gender_tfm: 'Trans Male (FTM or Female to Male)',
        gender_non_conforming: 'Gender non-conforming (i.e. not exclusively male or female)',
      }.map do |gender_scope, name|
        [
          name,
          GrdaWarehouse::Hud::Client.where(id: client_ids).send(gender_scope).count,
        ]
      end.to_h
    end

    def ssm_rows
      ssm_class = ::Health::SelfSufficiencyMatrixForm
      total_ssms = ssm_class.first_completed.where(patient_id: patient_ids).count
      {}.tap do |rows|
        ssm_class::SSM_QUESTION_TITLE.each do |score_attr, label|
          average = if total_ssms.positive?
            ssm_class.first_completed.where(patient_id: patient_ids).sum(score_attr) / total_ssms
          else
            0
          end

          rows[label] = average
        end
      end
    end

    COS_ROLLUPS = {
      '01 - IP PH' => 'Inpatient Medical', # Admits
      '02 - IP MAT' => 'Inpatient Maternity', # Admits
      '03 - IP BH' => 'Inpatient Behavioral Health', # Admits
      '04 - PROFSVC' => 'Professional Services',
      '05 - OP-BH' => 'Outpatient Behavioral Health',
      '05 - OP-BH CBHI' => 'Outpatient CBHI',
      '06 - OTH-OP' => 'Outpatient Other',
      '07 - ER' => 'Emergency Room',
      '08 - LAB-FAC' => 'Lab Facilities',
      '09 - DME' => 'DME',
      '10 - EMTRNS' => 'Emergency Transportation',
      '11 - LTC' => 'Long Term Care',
      '12 - OTH-MEDSVC' => 'Other Medical Services',
      '13 - HH' => 'Home Health',
    }.freeze

    COS_DESCRIPTIONS = {
      'I-01 BH' => 'Inpatient Behavioral Health',
      'I-01 MAT' => 'Inpatient Maternity',
      'I-01 SURG' => 'Inpatient Surgery',
      'I-01 MED' => 'Inpatient Medical',
      'I-04' => 'LTSS - Inpatient',
      'I-05' => 'Outpatient Ambulatory Surgery',
      'I-06' => 'Outpatient ER',
      'I-07' => 'Dialysis',
      'I-08' => 'Hospital Outpatient Clinic',
      'I-09' => 'Diagnostic Testing',
      'I-10' => 'Therapies',
      'I-11' => 'Nursing - Inpatient',
      'I-12' => 'Outpatient Behavioral Health/Substance Abuse',
      'I-13' => 'Hospice',
      'I-14' => 'Outpatient Imaging',
      'I-15' => 'Outpatient Lab',
      'I-16' => 'Drug',
      'I-17' => 'Blood Products',
      'I-18' => 'Oxygen & Respiratory',
      'I-19' => 'Emergency Transportation',
      'I-20' => 'DME/Supplies - Inpatient',
      'I-21' => '24 Hour Diversionary',
      'I-22' => 'Emergency Transportation',
      'I-23' => 'Institutional Other',

      'P-01' => 'Office/Home Services',
      'P-02' => 'Delivery',
      'P-03' => 'Surgery',
      'P-04' => 'Oncology Toxicology',
      'P-05' => 'Ophthalmology',
      'P-06' => 'Instit Services',
      'P-07' => 'Anesthesia',
      'P-08' => 'Behavioral Health',
      'P-09' => 'Therapies',
      'P-10' => 'Nursing - Office',
      'P-11' => 'Alternative Medicine',
      'P-12' => 'Diagnostic',
      'P-13' => 'Lab',
      'P-14' => 'Emergency Transportation',
      'P-15' => 'Non-emergency Transportation',
      'P-16' => 'Vision',
      'P-17' => 'DME/Supplies - Office',
      'P-18' => 'Inject/Infusion',
      'P-19' => 'Office Drugs',
      'P-20' => 'Dental',
      'P-21' => 'Hearing',
      'P-23' => 'Case Management',
      'P-24' => 'HCBS/Waiver Services',
      'P-25' => 'Telehealth',
      'P-26' => 'LTSS - Professional',
      'P-27' => 'Diversionary',
      'P-28' => 'Emergency Services Program',
      'P-29' => 'Children’s Behavioral Health Initiative (CBHI)',
      'P-30' => 'Methadone Admin',
      'P-31' => 'Imaging',
      'P-35' => 'Other Services',
    }.freeze

    def cos_rollup(code)
      COS_ROLLUPS.fetch(code, code)
    end

    def cos_description(code)
      COS_DESCRIPTIONS.fetch(code, code)
    end

    def selected_member_roster
      scope = member_roster

      # handle any member roster filtering here

      scope
    end

    private def selected_enrollments
      @enrollment_roster
    end

    private def selected_medical_claims
      scope = medical_claims
      # handle any claim based filters here
      scope
    end
  end
end
