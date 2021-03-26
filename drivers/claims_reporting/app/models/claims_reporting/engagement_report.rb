###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memoist'
module ClaimsReporting
  class EngagementReport
    include ActiveModel::Model
    extend Memoist
    attr_reader :member_roster, :rx_claims, :medical_claims, :claim_date_range

    def initialize(
      member_roster: ClaimsReporting::MemberRoster.all,
      claim_date_range: Date.iso8601('2020-01-01') .. Date.iso8601('2020-12-31')
    )
      @claim_date_range = claim_date_range
      @medical_claims = ClaimsReporting::MedicalClaim.where(
        service_start_date: claim_date_range,
      )
      @rx_claims = ClaimsReporting::RxClaim.where(
        service_start_date: claim_date_range,
      )
      @member_roster = member_roster
    end

    # Member classification bits from Milliman
    def available_filters
      filter_inputs.keys
    end

    # a Hash of filter attributes
    # mapping to
    # https://www.rubydoc.info/github/plataformatec/simple_form/SimpleForm%2FFormBuilder:input options for them
    def filter_inputs
      {
      }.freeze
    end

    def filter_options(filter)
      msg = "#{filter}_options"
      respond_to?(msg) ? send(msg) : nil
    end

    def detail_cols
      DETAIL_COLS
    end

    def roster_as_of
      claim_date_range.last
    end

    def report_days
      (claim_date_range.last.to_date - claim_date_range.first.to_date).to_i
    end

    def report_years
      report_days / 365.2422
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
                              Arel.sql(%[AVG(NULLIF(raw_dxcg_risk_score,'')::decimal)]).as('average_raw_dxcg_score'),
                            ), 'member_summary').with_indifferent_access
    end

    private def enrollment_summary
      connection.select_one(selected_enrollments.select(
                              Arel.sql(%[SUM(span_mem_days)]).as('span_mem_days'),
                            ), 'enrollment_summary').with_indifferent_access
    end

    private def claims_summary
      connection.select_one(selected_medical_claims.select(
                              Arel.sql(%[SUM(paid_amount)]).as('paid_amount'),
                            ), 'claims_summary').with_indifferent_access
    end

    def selection_summary
      member_summary.merge(enrollment_summary).merge(claims_summary)
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
      paid_amount = selection_summary[:paid_amount]

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

    def pct_with_pbd
      return unless selected_members&.positive?

      (selection_summary[:selected_pbd].to_d * 100.0 / selected_members)
    end

    def pct_with_das
      return unless selected_members&.positive?

      (selection_summary[:selected_das].to_d * 100.0 / selected_members)
    end

    def normalized_dxcg_score
      return unless selected_members&.positive?

      'TODO'
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
        ['Selected Members', "#{formatter.format_i selected_members} (#{formatter.format_pct percent_members_selected, precision: 1} of members)"],
        ['Average Age', formatter.format_d(average_age)],
        ['Member Months', formatter.format_d(member_months)],
        ['Average $PMPM', formatter.number_to_currency(average_per_member_per_month_spend)],
        ['Average Raw DxCG Score', formatter.format_d(average_raw_dxcg_score)],
        ['Normalized DxCG Score', formatter.format_d(normalized_dxcg_score)],
        ['% Female', formatter.format_pct(pct_female)],
      ]
    end

    DETAIL_COLS = {
      annual_admits_per_mille: 'Annual Utilization per 1,000', # admits
    }.freeze

    private def mrt
      member_roster.arel_table
    end

    private def mct
      medical_claims.arel_table
    end

    private def claims_query
      sql_member_id = "#{selected_medical_claims.quoted_table_name}.#{connection.quote_column_name :member_id}"

      sql_member_count = %[COUNT(DISTINCT #{sql_member_id})::numeric]

      annual_admits_per_mille = Arel.sql(
        %[NULLIF(
            ROUND(
              COUNT(DISTINCT
                CASE WHEN admit_date IS NOT NULL THEN CONCAT(#{sql_member_id}, admit_date)
              END
            )*1000/(#{sql_member_count}/#{report_years}))
            , 0)],
      ).as('annual_admits_per_mille')

      selected_medical_claims.group(
        Arel.sql(%[ROLLUP(1,2)]),
      ).select(
        Arel.sql(%[COALESCE(cde_cos_rollup,'Unclassified')]).as('cde_cos_rollup'),
        Arel.sql(%[COALESCE(cde_cos_category,'Unclassified')]).as('cde_cos_category'),
        annual_admits_per_mille,
      ).order('1 ASC NULLS FIRST,2 ASC NULLS FIRST')
    end

    private def connection
      HealthBase.connection
    end

    def engagement_rows
      return [] unless selected_members&.positive?

      connection.select_all(
        claims_query.where(
          cde_cos_category: [
            'I-01 MED',
            'I-01 SURG',
            'I-01 BH',
            'I-06',
            'I-05',
            'I-12',
            'I-22',
            'I-22',
            'I-22',
          ],
        ),
      )
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
      ClaimsReporting::MemberEnrollmentRoster.where(
        member_id: selected_medical_claims.select(:member_id),
      )
    end

    private def selected_medical_claims
      scope = medical_claims.joins(:member_roster).merge(selected_member_roster)
      # handle any claim based filters here
      scope
    end
  end
end
