require 'memoist'
module ClaimsReporting
  class PerformanceReport
    include ActiveModel::Model
    extend Memoist
    attr_reader :member_roster

    # member classifcation bits from Milliman

    # High_Util High Utilizing
    # COI Cohorts of Interest - All
    # High_ER_Flag Cohorts of Interest - 5+ ER Visits with No Psych Admissions
    # Psychoses_Flag Cohorts of Interest - 1+ Psychoses Admission
    # OthIPPsych_Flag Cohorts of Interest - 1+ Other IP Psych Admission

    # ENGAGEMENT_STATUS
    # CURRENTLY_ASSIGNED
    # CURRENTLY_ENGAGED

    # ENGAGED_MEMBER_DAYS

    # ANTIPSY_DAY
    # ANTIPSY_DENOM

    # ANTIDEP_DAY
    # ANTIDEP_DENOM

    # MOODSTAB_DAY
    # MOODSTAB_DENOM

    def available_filters
      [
        :age_bucket,
        :gender,
        :race,
        :aco,
        :mental_health_diagnosis_category,
        :medical_diagnosis_category,
        :currently_assigned,
      ].freeze
    end

    def filter_options(filter)
      msg = "#{filter}_options"
      respond_to?(msg) ? send(msg) : nil
    end

    # Age Bucket – The age of the member as of the report
    attr_accessor :age_bucket
    def age_bucket_options
      [
        '<18',
        '18-21',
        '22-29',
        '30-39',
        '40-49',
        '50-59',
        '60-64',
        '65+',
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
        othbh: 'Other',
      }.invert.to_a
    end

    # Medical Diagnosis Category – The medical diagnosis category represents a group of conditions
    # classified by medical diagnoses of specific interest in the Clinical Classification Software (CCS).
    # Every member is categorized as having a medical diagnosis based on the claims they
    # incurred - a member can be assigned to more than one category.
    # Possible medical diagnosis 'categories include:
    # ''
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
    attr_accessor :high_utilization_member

    # Cohorts of Interest– The user may select members based on their psychiatric inpatient and emergency room utilization history. The user can select the following utilization categories:
    # Cohorts of Interest– 1+ Psychoses Admission: patients that have had at least 1 inpatient admission for psychoses.
    # Cohorts of Interest– 1+ IP Psych Admission: patients that have had at least 1 non-psychoses psychiatric inpatient admission
    # Cohorts of Interest– 5+ ER Visits with No IP Psych Admission: patients that had at least 5 emergency room visits and no inpatient psychiatric admissions
    attr_accessor :cohort

    # Currently Assigned - If the member is still assigned to the CP as of the most recent member_roster
    attr_accessor :currently_assigned

    ## Member,
    # ENGAGEMENT_STATUS
    # ACO
    # AGE
    # sex
    # race
    # High_Util
    # COI
    # High_ER_Flag
    # Psychoses_Flag
    # OthIPPsych_Flag
    # CURRENTLY_ASSIGNED
    # CURRENTLY_ENGAGED
    # ENGAGED_MONTHS

    ## medical claim
    # css_id
    # assigned
    # is_acs
    # is_acs_demon
    # is_pp
    # is_pp_denom

    DETAIL_COLS = {
      member_count: 'member_count',
      # paid_amount_sum: 'paid_amount_sum',
      annual_admits_per_mille: 'Annual Admissions per 1,000', # admits
      avg_length_of_stay: 'Length of Stay', # days
      utilization_per_mille: 'Annual Utilization per 1,000', # days/cases/procedures/visits/scripts/etc
      pct_of_cohorit_with_utilization: '% of Selected Cohort with Utilization',
      avg_cost_per_service: 'Average Cost per Service (Paid $)',
      cohort_per_member_month_spend: 'Selected Cohort PMPM (Paid $)',
      pct_of_pop_spend_cohort: 'Cohort Spend as a % of Total Population Spend',
      pct_of_service_sepend_cohort: 'Selected Cohort Spend as a % of Service Line Population Spend',
      pct_of_admissions_acs: 'Percent of Admissions that are Ambulatory Care Sensitive',
      pct_of_cost_acs: 'Percent of Admission Cost that is Ambulatory Care Sensitive',
      pct_of_visits_perventable: 'Percent of ED/Observation/Urgent Care Visits that are Potentially Preventable',
      pct_of_cost_perventable: 'Percent of ED/Observation/Urgent Care Cost that is Potentially Preventable',
    }.freeze

    include ActiveSupport::NumberHelper

    def formatted_value(fld, row)
      val = row[fld.to_s]
      if fld.in?([:paid_amount_sum, :avg_cost_per_service, :cohort_per_member_month_spend])
        number_to_currency val
      elsif fld.to_s =~ /pct_of/
        number_to_percentage val, precision: 2
      elsif val.is_a? Numeric
        number_to_delimited val, precision: 2, separator: ','
      else
        val
      end
    end

    def initialize(member_roster: ClaimsReporting::MemberRoster.all)
      @member_roster = member_roster
    end

    def total_members
      medical_claims.distinct.count(:member_id)
    end
    memoize :total_members

    def selected_members
      selected_medical_claims.distinct.count(:member_id)
    end
    memoize :selected_members

    def percent_members_selected
      return 0 unless total_members&.positive? && selected_members&.positive?

      selected_members * 100.0 / total_members
    end
    memoize :selected_members

    def member_months
      'TODO'
    end
    memoize :member_months

    def average_per_member_per_month_spend
      'TODO'
    end
    memoize :average_per_member_per_month_spend

    def average_raw_dxcg_score
      selected_member_roster.average(%(NULLIF(raw_dxcg_risk_score,'')::decimal))&.round(2)
    end
    memoize :average_raw_dxcg_score

    def detail_cols
      DETAIL_COLS
    end

    def engagement_span
      # from the Milliman prototype -- mix max stay in days
      0 .. 9_999
    end

    def claims_query
      t = medical_claims.arel_table

      selected_medical_claims.group(
        :ccs_id,
      ).select(
        :ccs_id,
        Arel.star.count.as('count'),
        t[:member_id].count(true).as('member_count'),
        # t[:paid_amount].sum.as('paid_amount_sum'),
        Arel.sql('ROUND(AVG(paid_amount), 2)').as('avg_cost_per_service'),
        Arel.sql("ROUND(AVG(
          CASE
            WHEN discharge_date-admit_date < #{engagement_span.min} THEN NULL
            WHEN discharge_date-admit_date > #{engagement_span.max} THEN NULL
            ELSE discharge_date-admit_date
          END
        ))").as('avg_length_of_stay'),
      ).order('1 ASC NULLS LAST')
    end

    private def connection
      HealthBase.connection
    end

    def data
      connection.select_all(claims_query)
    end

    private def valid_option?(value, options)
      return unless value.present?

      options.detect do |opt|
        opt = opt.second if opt.is_a?(Array)
        opt.to_s == value.to_s
      end
    end

    def selected_member_roster
      dct = ClaimsReporting::MemberDiagnosisClassification
      scope = member_roster.left_joins(:diagnosis_classification)
      if valid_option?(age_bucket, age_bucket_options)
        min, max = *age_bucket.split(/[^\d]+/)
        min = (min.presence || 0).to_i
        max = (max.presence || 1_000).to_i
        # FIXME: Do we mean age at the time of service or age now?
        scope = scope.where(date_of_birth: max.years.ago.to_date .. min.years.ago.to_date)
      end

      scope = scope.where(race: race) if valid_option?(race, race_options)

      scope = scope.where(sex: gender) if valid_option?(gender, gender_options)

      scope = scope.merge(dct.where(mental_health_diagnosis_category.to_sym => true)) if valid_option?(mental_health_diagnosis_category, mental_health_diagnosis_category_options)

      scope = scope.merge(dct.where(medical_diagnosis_category.to_sym => true)) if valid_option?(medical_diagnosis_category, medical_diagnosis_category_options)

      scope = scope.merge(dct.where(currently_assigned: true)) if currently_assigned.present?

      scope
    end

    private def medical_claims
      ClaimsReporting::MedicalClaim
    end

    private def selected_medical_claims
      scope = medical_claims.joins(:member_roster).merge(selected_member_roster)
      # aco at the time of service
      scope = scope.where(aco_name: aco) if aco.present? && aco.in?(aco_options)

      scope
    end
  end
end
