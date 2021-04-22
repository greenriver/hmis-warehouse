# frozen_string_literal: true

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memoist'
require 'ruby-progressbar'

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

    def serializable_hash
      measure_info = AVAILABLE_MEASURES.values.map do |m|
        [m.id, {
          id: m.id,
          title: m.title,
          value: measure_value(m.id, report_nils_as: nil),
        }]
      end.to_h

      {
        title: title,
        date_range: date_range,
        measures: measure_info,
      }
    end

    def measure_value(measure, report_nils_as: '-')
      return report_nils_as unless measure.to_s.in?(AVAILABLE_MEASURES.keys.map(&:to_s)) && respond_to?(measure)

      send(measure) || report_nils_as
      # rescue StandardError => e
      #   logger.error e.inspect
      #   nil
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

    # BH CP enrollees 18 years of age or older as of September 2nd of the year prior to
    # the measurement year and 64 years of age as of December 31st of the measurement year.
    def dob_range_1
      (dec_31_of_measurement_yaer - 64.years) .. (date_range.min - 18.years)
    end
    memoize :dob_range_1

    # BH CP enrollees 18 to 64 years of age as of December 31st of the measurement year.
    def dob_range_2
      (dec_31_of_measurement_yaer - 64.years) .. (dec_31_of_measurement_yaer - 18.years)
    end
    memoize :dob_range_2

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

      puts "#{members_by_member_id.size} members"

      enrollments_by_member_id = assigned_enrollements_scope.select(
        :member_id,
        :cp_enroll_dt,
        :cp_stop_rsn,
      ).group_by(&:member_id)

      puts "#{assigned_enrollements_scope.count} enrollment spans"

      rows = []

      medical_claims_by_member_id = medical_claims_scope.select(
        :id,
        :member_id,
        #:cp_pidsl,
        :servicing_provider_type,
        :billing_provider_type,
        :service_start_date,
        :member_dob,
        :claim_type,
        :claim_status,
        :admit_date,
        :discharge_date,
        :procedure_code,
        :procedure_modifier_1,
        :procedure_modifier_2,
        :procedure_modifier_3,
        :procedure_modifier_4,
        :enrolled_days,
      ).group_by(&:member_id)

      puts "#{medical_claims_scope.count} medical_claims"

      pb = ProgressBar.create(total: medical_claims_by_member_id.size, format: '%c/%C (%P%%) %R/s%e [%B]')
      medical_claims_by_member_id.each do |member_id, claims|
        member = members_by_member_id[member_id]
        date_of_birth = member.date_of_birth
        enrollments = enrollments_by_member_id[member_id]
        assignment_date = enrollments.min_by(&:cp_enroll_dt).cp_enroll_dt
        completed_treatment_plans = claims.select(&:completed_treatment_plan?)

        # Members must be continuously enrolled in MassHealth during the measurement year.
        continuous_in_masshealth = continuously_enrolled_cp?(enrollments, date_range, max_gap: 45)

        # Members must be continuously enrolled in the BH CP for at least 122 calendar days.
        continuous_in_bh_cp = continuously_enrolled_cp?(enrollments, date_range, min_days: 122, max_gap: 0)

        # TODO? BH CP #2: The entity who submitted the documentation must be the same CP as the one that a member
        # is enrolled with on the anchor date and during the 122-day continuous enrollment period.

        rows << MeasureRow.new(
          row_type: 'enrollee', # spec also says "patients"/member
          row_id: member_id,
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
          if continuous_in_bh_cp && continuous_in_masshealth && date_of_birth.in?(dob_range_2)
            # Qualifying numerator activity does not need to occur during the 122-day continuous enrollment
            # period, and it can take place any time during the measurement year.
            row.bh_cp_2 = completed_treatment_plans.any? { |c| c.service_start_date.in? date_range }
          end
        end

        # a member might have multiple discharges
        rows.concat calculate_bh_cp_3(member, claims, enrollments)
        pb.increment
      end

      rows
    end
    memoize :medical_claim_based_rows

    private def continuously_enrolled_cp?(_enrollments, _date_range, max_gap: 0, min_days: nil) # rubocop:disable  Lint/UnusedMethodArgument
      # TODO: figure out of a group of enrollment spans indicate a continuous
      # enrollment. Optionally of a durations of at least min_days
      true
    end

    private def continuously_enrolled_mh?(_enrollments, _date_range, max_gap: 0, min_days: nil) # rubocop:disable  Lint/UnusedMethodArgument
      # TODO: figure out of a group of enrollment spans indicate a continuous
      # enrollment. Optionally of a durations of at least min_days
      true
    end

    private def in_age_range?(dob, range, as_of:)
      dob.in?(as_of - range.max .. as_of - range.min)
    end

    private def acute_inpatient_hospital?(_claim)
      # TODO: We need get a lookup of "Acute Inpatient Hospital IDs"
      # from somewhere
      false
    end

    private def calculate_bh_cp_3(_member, claims, enrollments)
      # Business days are defined as Monday through Friday, even
      # if one or more of those days is a state or federal holiday.
      raise 'invalid BusinessTime::Config.holidays' unless BusinessTime::Config.work_week == ['mon', 'tue', 'wed', 'thu', 'fri']
      raise 'invalid BusinessTime::Config.holidays' unless BusinessTime::Config.holidays.empty?

      # Exclude: Members who decline to engage with the BH CP. The reason for dis-enrollment from the
      # BH CP will be identified as Stop Reason “Declined” in the Medicaid Management Information System (MMIS).
      return [] if enrollments.any? { |e| e.cp_stop_rsn == 'Declined' } # Note: This is not populated as of Apr 2021

      servicing_provider_types = ['70', '71', '73', '74', '09', '26', '28']
      billing_provider_type = ['6', '3', '246', '248', '20', '21', '30', '31', '22', '332']

      billing_provider_type2 = ['1', '40', '301', '25']
      servicing_provider_types2 = ['35']

      discharge_date_range = date_range.min .. 3.business_days.before(date_range.max)

      rows = []

      # avoid O(n^2) by finding the small set of dates
      # containing the claims we are looking for near each discharge

      # Exclude discharges followed by readmission or direct transfer to a
      # facility setting within the 3- business-day follow-up period. To
      # identify readmissions and direct transfers to a facility setting:

      # 1. Identify all inpatient stays.
      # 2. Identify the admission date for the stay.

      # These discharges are excluded from the measure because a readmission
      # or direct transfer may prevent a follow-up from taking place.
      admit_dates = claims.select(&:admit_date).map(&:admit_date)

      # Qualifying Activity: Follow up after Discharge submitted by the BH CP to the Medicaid Management
      # Information System (MMIS) and identified via code G9007 with a U5 modifier. In addition to the
      # U5 modifier...
      # TODO: the following modifiers may be included: U1 or U2). This follow- up must be comprised
      # of a face-to-face visit with the enrollee.
      eligable_followups = claims.select do |c|
        c.procedure_code == 'G9007' && c.modifiers.include?('U5')
        # TODO: The follow- up must be with the same BH CP that a member is enrolled with on the event date (discharge date).
      end.map(&:service_start_date)

      claims.each do |c|
        # on or between January 1 and more than 3 business days before the end of the measurement year.
        next unless c.discharge_date && c.discharge_date.in?(discharge_date_range)

        # BH CP enrollees 18 to 64 years of age as of date of discharge.
        next unless in_age_range?(c.member_dob, 18.years .. 64.years, as_of: c.discharge_date)

        # A discharge from any facility setting listed below
        next unless (
          c.servicing_provider_type.in?(servicing_provider_types) ||
          c.billing_provider_type.in?(billing_provider_type) ||
          (acute_inpatient_hospital?(c) && c.billing_provider_type.in?(billing_provider_type2))
        ) || (
          c.claim_type == 'inpatient' && c.servicing_provider_type.in?(servicing_provider_types2)
        )

        # Continuously enrolled with BH CP from date of discharge through 3 business days after discharge.
        # No allowable gap in BH CP enrollment during the continuous enrollment period.
        followup_period = (c.discharge_date .. 3.business_days.after(c.discharge_date)).to_a
        next unless continuously_enrolled_cp?(enrollments, followup_period, max_gap: 0)

        # exclude readmitted
        next if (admit_dates & followup_period).any?

        # count in the numerator if we had a eligable_followups in the period
        eligable_followup = (eligable_followups & followup_period).any?

        row = MeasureRow.new(
          row_type: 'discharge',
          row_id: c.id,
          bh_cp_3: eligable_followup,
        )
        # puts "Found #{row.inspect}"

        rows << row
      end
      rows
    end

    def assigned_enrollees
      formatter.format_i assigned_enrollements_scope.count
    end
    memoize :assigned_enrollees

    def medical_claims
      formatter.format_i medical_claims_scope.count
    end
    memoize :medical_claims

    private def percentage(enumerable, flag)
      denominator = 0
      numerator = 0
      enumerable.each do |r|
        value = r.send(flag)
        next if value.nil? # not part of this measure

        denominator += 1
        numerator += 1 if value
      end

      return nil if denominator.zero?

      # formatter.format_pct(numerator * 100.0 / denominator).presence
      [numerator, denominator]
      # formatter.format_pct(numerator * 100.0 / denominator).presence
    end

    def bh_cp_1
      percentage medical_claim_based_rows, :bh_cp_1
    end

    def bh_cp_2
      percentage medical_claim_based_rows, :bh_cp_2
    end

    def bh_cp_3
      percentage medical_claim_based_rows, :bh_cp_3
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

    VALUE_SETS = {
      'AOD Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1013',
      'AOD Medication Treatment' => '2.16.840.1.113883.3.464.1004.2017',
      'Acute Inpatient' => '2.16.840.1.113883.3.464.1004.1017',
      'Alcohol Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1424',
      'Ambulatory Surgical Center POS' => '2.16.840.1.113883.3.464.1004.1480',
      'BH Outpatient' => '2.16.840.1.113883.3.464.1004.1481',
      'Community Mental Health Center POS' => '2.16.840.1.113883.3.464.1004.1484',
      'Detoxification' => '2.16.840.1.113883.3.464.1004.1076',
      'Diabetes' => '2.16.840.1.113883.3.464.1004.1077',
      'ED' => '2.16.840.1.113883.3.464.1004.1086',
      'ED POS' => '2.16.840.1.113883.3.464.1004.1087',
      'Electroconvulsive Therapy' => '2.16.840.1.113883.3.464.1004.1294',
      'HbA1c Tests' => '2.16.840.1.113883.3.464.1004.1116',
      'Hospice' => '2.16.840.1.113883.3.464.1004.1418',
      'IET POS Group 1' => '2.16.840.1.113883.3.464.1004.1129',
      'IET POS Group 2' => '2.16.840.1.113883.3.464.1004.1130',
      'IET Stand Alone Visits' => '2.16.840.1.113883.3.464.1004.1131',
      'IET Visits Group 1' => '2.16.840.1.113883.3.464.1004.1132',
      'IET Visits Group 2' => '2.16.840.1.113883.3.464.1004.1133',
      'Inpatient Stay' => '2.16.840.1.113883.3.464.1004.1395',
      'Intentional Self-Harm' => '2.16.840.1.113883.3.464.1004.1468',
      'Mental Health Diagnosis' => '2.16.840.1.113883.3.464.1004.1178',
      'Mental Illness' => '2.16.840.1.113883.3.464.1004.1179',
      'Nonacute Inpatient' => '2.16.840.1.113883.3.464.1004.1189',
      'Nonacute Inpatient Stay' => '2.16.840.1.113883.3.464.1004.1398',
      'Observation' => '2.16.840.1.113883.3.464.1004.1191',
      'Online Assessments' => '2.16.840.1.113883.3.464.1004.1446',
      'Opioid Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1425',
      'Outpatient' => '2.16.840.1.113883.3.464.1004.1202',
      'Outpatient POS' => '2.16.840.1.113883.3.464.1004.1443',
      'Partial Hospitalization POS' => '2.16.840.1.113883.3.464.1004.1491',
      'Partial Hospitalization/Intensive Outpatient' => '2.16.840.1.113883.3.464.1004.1492',
      'Telehealth Modifier' => '2.16.840.1.113883.3.464.1004.1445',
      'Telehealth POS' => '2.16.840.1.113883.3.464.1004.1460',
      'Telephone Visits' => '2.16.840.1.113883.3.464.1004.1246',
      'Transitional Care Management Services' => '2.16.840.1.113883.3.464.1004.1462',
      'Visit Setting Unspecified' => '2.16.840.1.113883.3.464.1004.1493',
      'Well-Care' => '2.16.840.1.113883.3.464.1004.1262',
    }.freeze

    # TODO
    # ["AOD Abuse and Dependence",
    # "AOD Medication Treatment",
    # "Acute Inpatient",
    # "Alcohol Abuse and Dependence",
    # "Ambulatory Surgical Center POS",
    # "BH Outpatient",
    # "Community Mental Health Center POS",
    # "Detoxification",
    # "Diabetes",
    # "ED",
    # "ED POS",
    # "Electroconvulsive Therapy",
    # "HbA1c Tests",
    # "Hospice",
    # "IET POS Group 1",
    # "IET POS Group 2",
    # "IET Stand Alone Visits",
    # "IET Visits Group 1",
    # "IET Visits Group 2",
    # "Inpatient Stay",
    # "Intentional Self-Harm",
    # "Mental Health Diagnosis",
    # "Mental Illness",
    # "Nonacute Inpatient",
    # "Nonacute Inpatient Stay",
    # "Observation",
    # "Online Assessments",
    # "Opioid Abuse and Dependence",
    # "Outpatient",
    # "Outpatient POS",
    # "Partial Hospitalization POS",
    # "Partial Hospitalization/Intensive Outpatient",
    # "Telehealth Modifier",
    # "Telehealth POS",
    # "Telephone Visits",
    # "Transitional Care Management Services",
    # "Visit Setting Unspecified",
    # "Well-Care"

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
