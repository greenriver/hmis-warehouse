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

    Measure = Struct.new(:id, :title, :desc, :numerator, :denominator, keyword_init: true)

    AVAILABLE_MEASURES = [
      Measure.new(
        id: :bh_cp_1,
        title: 'BH CP #1: Community Partner Engagement (122 days) - % patients',
        desc: 'The percentage of Behavioral Health Community Partner (BH CP) assigned enrollees 18 to 64 years of age with documentation of engagement within 122 days of the date of assignment to a BH CP.',
        numerator: 'BH CP assigned enrollees 18 to 64 years of age who had documentation of engagement within 122 days of the date of assignment.',
        denominator: 'BH CP assigned enrollees 18 to 64 years of age as of December 31st of the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_2,
        title: 'BH CP #2: Annual Treatment Plan Completion - % patients',
        desc: 'The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with documentation of a completed Treatment Plan during the measurement year.',
        numerator: 'BH CP enrollees 18 to 64 years of age who had documentation of a completed Treatment Plan during the measurement year. Treatment plan must be completed by the CP with whom the member met continuous enrollment requirement',
        denominator: 'BH CP enrollees 18 to 64 years of age as of December 31st of the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_3,
        title: 'BH CP #3: Follow-up with BH CP after acute or post-acute stay (3 business days) - % stays',
        desc: 'The percentage of discharges from acute or post-acute stays for Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age that were succeeded by a follow-up with the BH CP within 3 business days of discharge.',
        numerator: 'Discharges for BH CP enrollees 18 to 64 years of age that were succeeded by a follow-up with the BH CP within 3 business days of discharge.',
        denominator: 'Discharges for BH CP enrollees 18 to 64 years of age during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_4,
        title: 'BH CP #4: Follow-up with BH CP after Emergency Department visit',
        desc: 'The percentage of emergency department (ED) visits for Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age that had a follow-up visit within 7 calendar days of the ED visit.',
        numerator: 'Discharges from the ED for BH CP enrollees 18 to 64 years of age that were succeeded by a follow-up with the BH CP within 7 calendar days after discharge.',
        denominator: 'Discharges from the ED for BH CP enrollees 18 to 64 years of age during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_5,
        title: 'BH CP #5: Annual Primary Care Visit - % patients',
        desc: 'The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age who had at least one comprehensive well-care visit with a PCP or an OB/GYN practitioner during the measurement year.',
        numerator: 'BH CP enrollees 18 to 64 years of age who received a comprehensive well-care visit at least one time during the measurement year.',
        denominator: 'BH CP enrollees 18 to 64 years of age as of December 31 of the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_6,
        title: 'BH CP #6: Community Tenure',
        desc: 'The percentage of eligible days that BH CP assigned members 21 to 64 years of age reside in their home or in a community setting without utilizing acute, chronic, or post- acute institutional health care services during the measurement year.',
        numerator: 'The sum of eligible days that BH CP assigned members 21 to 64 years of age reside in their home or in a community without utilizing acute, chronic, or post-acute institutional health care services during the measurement year.',
        denominator: 'The sum of eligible days of members that are enrolled in a BH CP during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_7_and_8,
        title: 'BH CP #7/#8: Initiation and Engagement of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
        desc: <<~TXT,
          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with a new episode of alcohol, opioid,
          or other drug (AOD) abuse or dependence who received the following.

          - Initiation of AOD Treatment. The percentage of enrollees who initiate treatment through an inpatient AOD admission,
            outpatient visit, intensive outpatient encounter or partial hospitalization, telehealth or medication assisted treatment
            (medication treatment) within 14 days of the diagnosis.
          - Engagement of AOD Treatment. The percentage of enrollees who initiated treatment and who had two or more additional
            AOD services or medication treatment within 34 days of the initiation visit.
        TXT
        numerator: 'BH CP enrollees 18 to 64 years of age who initiate/engage with AOD treatment.',
        denominator: 'BH CP enrollees 18 to 64 years of age with a new episode of AOD during the intake period.',
      ),
      Measure.new(
        id: :bh_cp_9,
        title: 'BH CP #9: Follow-Up After Hospitalization for Mental Illness (7 days) - % events',
        desc: '',
        numerator: '',
        denominator: '',
      ),
      Measure.new(
        id: :bh_cp_10,
        title: 'BH CP #10: Diabetes Screening for Individuals With Schizophrenia or Bipolar Disorder Who Are Using Antipsychotic Medications',
        desc: '',
        numerator: '',
        denominator: '',
      ),
      Measure.new(
        id: :bh_cp_11,
        title: 'BH CP #12: Emergency Department Visits for Adults with Mental Illness, Addiction, or Co-occurring Conditions',
        desc: '',
        numerator: '',
        denominator: '',
      ),
      Measure.new(
        id: :bh_cp_13,
        title: 'BH CP #13: Hospital Readmissions (Adult)',
        desc: '',
        numerator: '',
        denominator: '',
      ),
      Measure.new(
        id: :assigned_enrollees,
        title: 'assigned enrollees',
      ),
      Measure.new(
        id: :medical_claims,
        title: 'medical service claims',
      ),
    ].index_by(&:id).freeze

    # we are keeping rows of each enrollee, etc and flags for each measure
    # with three possible values: nil (not in the univierse for the measure), false part of the denominator only, true part of the numerator
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
    rescue StandardError
      nil
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
      scope.where(
        member_id: ::ClaimsReporting::MemberRoster.where(date_of_birth: dob_range_1).select(:member_id),
      )
    end

    def dec_31_of_measurement_yaer
      date_range.min.end_of_year
    end
    memoize :dec_31_of_measurement_yaer

    # BH CP enrollees 18 years of age or older as of September 2nd of the year prior to
    # the measurement year and 64 years of age as of December 31st of the measurement year.
    def dob_range_1
      (dec_31_of_measurement_yaer - 64.years) .. (date_range.min - 18.years)
    end

    # BH CP enrollees 18 to 64 years of age as of December 31st of the measurement year.
    def dob_range_2
      (dec_31_of_measurement_yaer - 64.years) .. (dec_31_of_measurement_yaer - 18.years)
    end

    def medical_claims_scope
      ClaimsReporting::MedicalClaim.joins(
        :member_roster,
      ).where(
        member_id: assigned_enrollements_scope.select(:member_id),
      ).service_in(date_range)
    end

    def medical_claim_based_rows
      members_by_member_id = ::ClaimsReporting::MemberRoster.where(
        member_id: assigned_enrollements_scope.select(:member_id),
      ).select(
        :member_id,
        :date_of_birth,
      ).index_by(&:member_id)

      enrollments_by_member_id = assigned_enrollements_scope.select(
        :member_id,
        :cp_enroll_dt,
      ).group_by(&:member_id)

      [].tap do |rows|
        medical_claims_scope.select(
          :member_id,
          :cp_pidsl,
          :service_start_date,
          :member_dob,
          :discharge_date,
          :procedure_code,
          :procedure_modifier_1,
          :procedure_modifier_2,
          :procedure_modifier_3,
          :procedure_modifier_4,
        ).group_by(&:member_id).each do |member_id, claims|
          date_of_birth = members_by_member_id[member_id].date_of_birth
          enrollments = enrollments_by_member_id[member_id]
          earliest_enrollment = enrollments.min_by(&:cp_enroll_dt)
          assignment_date = earliest_enrollment.cp_enroll_dt
          completed_treatment_plans = claims.select { |c| c.procedure_code == 'T2024' && 'U4'.in?(c.modifiers) }

          rows << MeasureRow.new(
            row_type: 'enrollee', # spec also says "patients"/member
            row_id: member_id,
            assigned_enrollees: true,
          ).tap do |row|
            row.medical_claims = claims.count

            # BH CP #1 The percentage of Behavioral Health Community Partner (BH CP)
            # assigned enrollees 18 to 64 years of age with documentation of engagement
            # within 122 days of the date of assignment to a BH CP.
            if date_of_birth.in?(dob_range_1)
              cut_off_date = assignment_date + 122.days
              row.bh_cp_1 = completed_treatment_plans.any? { |c| c.service_start_date <= cut_off_date }
            end

            # BH CP #2: The percentage of Behavioral Health Community Partner (BH CP) enrollees
            # 18 to 64 years of age with documentation of a completed Treatment Plan during the
            # measurement year.
            # anchor_date = dob_range_2.max

            # Members must be continuously enrolled in MassHealth during the measurement year.
            continuous_in_masshealth = true # TODO "a gap of no more than 45 calendar days"
            # Members must be continuously enrolled in the BH CP for at least 122 calendar days.
            continuous_in_bh_cp = true # TODO  "no gap is allowed in CP enrollment"
            if continuous_in_bh_cp && continuous_in_masshealth && date_of_birth.in?(dob_range_2)
              # Qualifying numerator activity does not need to occur during the 122-day continuous enrollment
              # period, and it can take place any time during the measurement year.
              # TODO? The entity who submitted the documentation must be the same CP as the one that a member
              # is enrolled with on the anchor date and during the 122-day continuous enrollment period.
              row.bh_cp_2 = completed_treatment_plans.any? { |c| c.service_start_date.in? date_range }
            end
          end

          # claims.each do |c|
          # next unless c.servicing_provider_type.in? %w/70 71 73 74 09 26 28/
          # next unless c.servicing_provider_type.in? %w/35/  && c.claim_type == 'inpatient'

          #   anchor_date = c.discharge_date
          #   # BH CP enrollees 18 to 64 years of age as of date of discharge.
          #   next unless c.member_dob.in?(anchor_date - 64.years .. anchor_date - 18.years)

          #   followup_range = anchor_date .. 3.business_days.after(anchor_date)
          #   # TODO: Continuously enrolled with BH CP from date of discharge through 3 business days after discharge.
          #   overlapping_enrollments = enrollments.select{|e|}

          #   # TODO: No allowable gap in BH CP enrollment during the continuous enrollment period.

          #   # TODO: table/column for MassHealth Provider Type && MCO or ACO Provider Type

          #   # Qualifying Activity: Follow up after Discharge submitted by the BH CP to the Medicaid Management
          #   # Information System (MMIS) and identified via code G9007 with a U5 modifier. In addition to the
          #   # U5 modifier, (TODO: the following modifiers may be included: U1 or U2). This follow- up must be comprised
          #   # of a face-to-face visit with the enrollee.
          #   # TODO: The follow- up must be with the same BH CP that a member is enrolled with on the event date (discharge date).
          #   eligable_followup = claims.any? do |c|
          #     c.procedure_code == 'G9007' && c.modifiers.include?('U5') && c.service_start_date.in?(followup_range)
          #   end
          #   rows << MeasureRow.new(
          #     row_type: 'discharge',
          #     row_id: c.id,
          #     bh_cp_3: eligable_followup,
          #   )
          # end
        end
      end
    end
    memoize :medical_claim_based_rows

    def assigned_enrollees
      formatter.format_i medical_claim_based_rows.size
    end

    def medical_claims
      formatter.format_i medical_claim_based_rows.sum(&:medical_claims)
    end

    private def percentage(enumerable, flag)
      denominator = 0
      numerator = 0
      enumerable.each do |r|
        value = r.send(flag)
        next if value.nil? # not part of this measure

        denominator += 1
        numerator += 1 if value
      end

      formatter.format_pct(numerator * 100.0 / denominator).presence
    end

    def bh_cp_1
      percentage medical_claim_based_rows, :bh_cp_1
    end

    def bh_cp_2
      percentage medical_claim_based_rows, :bh_cp_2
    end

    def bh_cp_3
      # percentage medical_claim_based_rows, :bh_cp_3
    end

    def bh_cp_4
      # percentage medical_claim_based_rows, :bh_cp_4
    end

    def bh_cp_5
      # percentage medical_claim_based_rows, :bh_cp_5
    end

    def bh_cp_6
    end

    def bh_cp_7_and_8
    end

    def bh_cp_9
      # percentage medical_claim_based_rows, :bh_cp_9
    end

    def bh_cp_10
    end

    def bh_cp_11
    end

    def bh_cp_13
      # percentage medical_claim_based_rows, :bh_cp_13
    end

    # private def values_sets
    #   [
    #     'Acute Inpatient POS Value Set'.
    #     'Acute Inpatient Value Set'.
    #     'Alcohol Abuse and Dependence Value Set'.
    #     'Ambulatory Surgical Center POS Value Set'.
    #     'AOD Abuse and Dependence Value Set'.
    #     'AOD Medication Treatment Value Set'.
    #     'BH Outpatient Value Set'.
    #     'BH Stand Alone Acute Inpatient Value Set'.
    #     'BH Stand Alone Nonacute Inpatient Value Set'.
    #     'Bipolar Disorder Value Set'.
    #     'Community Mental Health Center POS Value Set'.
    #     'Detoxification Value Set'.
    #     'Diabetes Value Set'.
    #     'ED POS Value Set'.
    #     'ED Value Set'.
    #     'Electroconvulsive Therapy Value Set'.
    #     'Glucose Tests Value Set'.
    #     'HbA1c Tests Value Set'.
    #     'Hospice Value Set'.
    #     'IET POS Group 1 Value Set'.
    #     'IET POS Group 2 Value Set'.
    #     'IET Stand Alone Visits Value Set'.
    #     'IET Visits Group 1 Value Set'.
    #     'IET Visits Group 2 Value Set'.
    #     'Inpatient Stay Value Set'.
    #     'Intentional Self-Harm Value Set'.
    #     'Long-Acting Injections Value Set'.
    #     'Mental Health Diagnosis Value Set'.
    #     'Mental Illness Value Set'.
    #     'Nonacute Inpatient POS Value Set'.
    #     'Nonacute Inpatient Stay Value Set'.
    #     'Nonacute Inpatient Value Set'.
    #     'Observation Value Set'.
    #     'Online Assessments Value Set'.
    #     'Opioid Abuse and Dependence Value Set'.
    #     'Other Bipolar Disorder Value Set'.
    #     'Other Drug Abuse and Dependence Value Set              '.
    #     'Outpatient POS Value Set'.
    #     'Outpatient Value Set'.
    #     'Partial Hospitalization POS Value Set'.
    #     'Partial Hospitalization/Intensive Outpatient Value Set'.
    #     'Schizophrenia Value Set'.
    #     'Serious Mental Illness, Value Set - Principal ICD-10 CM Diagnosis'.
    #     'Telehealth Modifier Value Set'.
    #     'Telehealth POS Value Set'.
    #     'Telephone Visits Value Set'.
    #     'Transitional Care Management Services Value Set'.
    #     'Visit Setting Unspecified Value Set'.
    #     'Well-Care Value Set'.
    #   ]
    # end

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
