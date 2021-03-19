###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memoist'
module ClaimsReporting
  class QualityMeasuresReport
    include ActiveModel::Model
    extend Memoist
    attr_reader :title, :date_range

    def initialize(
      title:,
      date_range:
    )
      @title = title
      @date_range = date_range
    end

    AVAILABLE_MEASURES = {
      assigned_enrollees: 'Assigned enrollees',
      bh_cp_1: 'BH CP #1: Community Partner Engagement (122 days) - % patients',
      bh_cp_2: 'BH CP #2: Annual Treatment Plan Completion - % patients',
      bh_cp_3: 'BH CP #3: Follow-up with BH CP after acute or post- acute stay (3 business days) - % stays',
      bh_cp_4: 'BH CP #4: Follow-up with BH CP after Emergency Department visit',
      bh_cp_5: 'BH CP #5: Annual Primary Care Visit - % patients',
      bh_cp_6: 'BH CP #6: Community Tenure',
      bh_cp_7_and_8: 'BH CP #7/#8: Initiation and Engagement of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
      bh_cp_9: 'BH CP #9: Follow-Up After Hospitalization for Mental Illness (7 days) - % events',
      bh_cp_10: 'BH CP #10: Diabetes Screening for Individuals With Schizophrenia or Bipolar Disorder Who Are Using Antipsychotic Medications',
      bh_cp_11: 'BH CP #12: Emergency Department Visits for Adults with Mental Illness, Addiction, or Co-occurring Conditions',
      bh_cp_13: 'BH CP #13: Hospital Readmissions (Adult)',
    }.freeze
    MeasureRow = Struct.new(:row_type, :row_id, *AVAILABLE_MEASURES.keys, keyword_init: true)

    # The percentage of Behavioral Health Community Partner (BH CP) assigned enrollees 18 to 64 years of age with documentation of engagement within 122 days of the date of assignment to a BH CP.

    def self.for_plan_year(year)
      year = year.to_i
      new(
        title: "PY#{year}",
        date_range: Date.iso8601("#{year - 1}-09-02") .. Date.iso8601("#{year}-09-01"),
      )
    end

    def measure_value(measure, report_nils_as: '-')
      return report_nils_as unless measure.to_s.in?(AVAILABLE_MEASURES.keys.map(&:to_s)) && respond_to?(measure)

      send(measure) || report_nils_as
    end

    # BH CP assigned enrollees 18 to 64 years of age as of December 31st of the measurement year.

    def assigned_enrollements_scope
      # Members assigned to a BH CP on or between September 2nd of the year prior to the
      # measurement year and September 1st of the measurement year.
      scope = ::ClaimsReporting::MemberEnrollmentRoster
      e_t = scope.quoted_table_name
      # scope = scope.where(enrolled_flag: 'Y')
      scope = scope.where(
        ["#{e_t}.cp_enroll_dt <= :max and (#{e_t}.cp_disenroll_dt IS NULL OR #{e_t}.cp_disenroll_dt > :max)", {
          min: date_range.min,
          max: date_range.max,
        }],
      )
      scope.joins(:member_roster).merge(::ClaimsReporting::MemberRoster.where(date_of_birth: dob_range))
    end

    # BH CP enrollees 18 years of age or older as of September 2nd of the year prior to
    # the measurement year and 64 years of age as of December 31st of the measurement year.
    def dob_range
      (date_range.max.end_of_year - 64.years) .. (date_range.min - 18.years)
    end

    def medical_claims_scope
      ClaimsReporting::MedicalClaim.where(
        member_id: assigned_enrollements_scope.select(:member_id),
      ).service_overlaps(date_range)
    end

    def medical_claim_based_rows
      medical_claims_scope.group_by(&:member_id).map do |member_id, claims|
        MeasureRow.new(
          row_type: 'enrollee',
          row_id: member_id,
          assigned_enrollees: true,
        ).tap do |row|
          puts "#{member_id} #{claims.map(&:procedure_code).uniq}"

          row.bh_cp_1 = claims.any?(&:bh_cp_1?)
        end
      end
    end
    memoize :medical_claim_based_rows

    def assigned_enrollees
      medical_claim_based_rows.size
    end

    private def percentage(numerator, denominator)
      return nil if denominator.zero?

      formatter.format_pct(numerator * 100.0 / denominator).presence
    end

    def bh_cp_1
      # The following activities must be completed to constitute engagement
      # with a BH CP:

      # - The BH CP has completed a Comprehensive Assessment and Person-
      # Centered Treatment Plan

      # - The Person-Centered Treatment Plan has been signed or otherwise
      # approved by the assigned enrollee (or their legally authorized
      # representative, as appropriate)

      # - The Person-Centered Treatment Plan has been approved by the assigned
      # enrollee’s primary care physician (PCP) (or their PCP designee)

      # - Submission of a “BH CP Treatment Plan Complete” Qualifying Activity
      # by the BH CP to the Medicaid Management Information System (MMIS) and
      # identified via code T2024 with U4 Modifier.

      percentage medical_claim_based_rows.select(&:bh_cp_1).size, medical_claim_based_rows.size
    end

    def bh_cp_2
    end

    def bh_cp_3
    end

    def bh_cp_4
    end

    def bh_cp_5
    end

    def bh_cp_6
    end

    def bh_cp_7_and_8
    end

    def bh_cp_9
    end

    def bh_cp_10
    end

    def bh_cp_11
    end

    def bh_cp_13
    end

    private def connection
      HealthBase.connection
    end

    private def formatter
      ClaimsReporting::Formatter.new
    end
    memoize :formatter

    # Member classification bits from Milliman
    def available_filters
      filter_inputs.keys
    end

    # a Hash of filter attributes
    # mapping to
    # https://www.rubydoc.info/github/plataformatec/simple_form/SimpleForm%2FFormBuilder:input options for them
    def filter_inputs
      {
        age_bucket: {
          label: _('Age Bucket'),
          collection: age_bucket_options, include_blank: '(any)',
          hint: "Member's reported age as of #{roster_as_of}"
        },
        gender: {
          label: _('Gender'),
          collection: gender_options, include_blank: '(any)',
          hint: "Member's reported gender as of #{roster_as_of}"
        },
        race: {
          label: _('Race'),
          collection: race_options,
          include_blank: '(any)',
          hint: "Member's reported race as of #{roster_as_of}",
        },
      }.freeze
    end

    def filter_options(filter)
      msg = "#{filter}_options"
      respond_to?(msg) ? send(msg) : nil
    end

    # Age Bucket – The age of the member as of the report
    attr_accessor :age_bucket

    def age_bucket_options
      [
        '<18', # never used
        '18-21',
        '22-29',
        '30-39',
        '40-49',
        '50-59',
        '60-64',
        '65+', # never used
      ].freeze
    end

    # Gender – The member’s gender
    attr_accessor :gender

    def gender_options
      # member_roster.group(:sex).count.keys
      ['Female', 'Male'].freeze
    end

    # Race – The member’s race
    attr_accessor :race

    def race_options
      # member_roster.group(:race).count.keys
      # American Indian Or Alaskan American
      # Asian Or Pacific Islander
      # Black-Not Of Hispanic Origin
      # Caucasian
      # Hispanic
      # Interracial
      # Race Unknown
      [
        # FIXME: '(blank)',
        'AMERICAN INDIAN OR ALASKAN AMERICAN',
        'ASIAN OR PACIFIC ISLANDER',
        'BLACK-NOT OF HISPANIC ORIGIN',
        'CAUCASIAN',
        'HISPANIC',
        'INTERRACIAL',
        'RACE UNKNOWN',
      ].freeze
    end

    # ACO – The ACO that the member was assigned to at the time the claim is incurred
    attr_accessor :aco

    def aco_options
      # FIXME: '(blank)',
      medical_claims.distinct.pluck(:aco_name).compact.sort.freeze
    end
    memoize :aco_options

    # Mental Health Diagnosis Category –
    # The mental health diagnosis category represents a group of conditions
    # classified by mental health and substance abuse categories included
    # in the Clinical Classification Software (CCS) available at
    # https://www.hcup-us.ahrq.gov/toolssoftware/ccs/ccsfactsheet.jsp.
    #
    attr_accessor :mental_health_diagnosis_category

    def mental_health_diagnosis_category_options
      {
        sch: 'Schizophrenia',
        pbd: 'Psychoses/Bipolar Disorders',
        das: 'Depression/Anxiety/Stress Reactions',
        pid: 'Personality/Impulse Disorder',
        sia: 'Suicidal Ideation/Attempt',
        sud: 'Substance Abuse Disorder',
        other_bh: 'Other',
      }.invert.to_a
    end

    # Medical Diagnosis Category – The medical diagnosis category represents a group of conditions
    # classified by medical diagnoses of specific interest in the Clinical Classification Software (CCS).
    # Every member is categorized as having a medical diagnosis based on the claims they
    # incurred - a member can be assigned to more than one category.
    attr_accessor :medical_diagnosis_category

    def medical_diagnosis_category_options
      {
        ast: 'Asthma',
        cpd: 'COPD',
        cir: 'Cardiac Disease',
        dia: 'Diabetes',
        spn: 'Degenerative Spinal Disease/Chronic Pain',
        gbt: 'GI and Biliary Tract Disease',
        obs: 'Obesity',
        hyp: 'Hypertension',
        hep: 'Hepatitis',
      }.invert.to_a
    end

    # High Utilizing Member – ‘High Utilizing’ represents high utilizers (3+ inpatient stays or 5+ emergency room visits throughout their claims experience).
    attr_accessor :high_util

    # Cohorts of Interest– The user may select members based on their psychiatric inpatient and emergency room utilization history. The user can select the following utilization categories:
    attr_accessor :coi

    def coi_options
      {
        coi: 'All COIs',
        psychoses: '1+ Psychoses Admission: patients that have had at least 1 inpatient admission for psychoses.',
        other_ip_psych: '1+ IP Psych Admission: patients that have had at least 1 non-psychoses psychiatric inpatient admission',
        high_er: '5+ ER Visits with No IP Psych Admission: patients that had at least 5 emergency room visits and no inpatient psychiatric admissions',
      }.invert.to_a
    end
  end
end
