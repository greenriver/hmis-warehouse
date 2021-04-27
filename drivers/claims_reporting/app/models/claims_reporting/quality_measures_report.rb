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

    private def logger
      Rails.logger
    end

    Measure = Struct.new(:id, :title, :desc, :numerator, :denominator, keyword_init: true)

    PROCEDURE_CODE_SYSTEMS = ['CPT', 'HCPCS'].freeze
    REVENUE_CODE_SYSTEMS = ['UBREV'].freeze
    APC_EXTRA_PROC_CODES = ['99386', '99387', '99396', '99397', 'T1015'].freeze

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
        id: :bh_cp_7,
        title: 'BH CP #7/#8: Initiation and Engagement of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
        desc: <<~TXT,
          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with a new episode of alcohol, opioid,
          or other drug (AOD) abuse or dependence who received the following.

          - Initiation of AOD Treatment. The percentage of enrollees who initiate treatment through an inpatient AOD admission,
            outpatient visit, intensive outpatient encounter or partial hospitalization, telehealth or medication assisted treatment
            (medication treatment) within 14 days of the diagnosis.
        TXT
        numerator: 'BH CP enrollees 18 to 64 years of age who initiate/engage with AOD treatment.',
        denominator: 'BH CP enrollees 18 to 64 years of age with a new episode of AOD during the intake period.',
      ),
      Measure.new(
        id: :bh_cp_8,
        title: 'BH CP #7/#8: Initiation and Engagement of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
        desc: <<~TXT,
          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with a new episode of alcohol, opioid,
          or other drug (AOD) abuse or dependence who received the following.

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
        date_range: Date.iso8601("#{year}-01-01") .. Date.iso8601("#{year}-12-31"),
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
      # TODO: handle "September"
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

    # TODO: handle "September"
    # BH CP enrollees 18 years of age or older as of September 2nd of the year prior to
    # the measurement year and 64 years of age as of December 31st of the measurement year.
    def dob_range_1
      (dec_31_of_measurement_year - 64.years) .. (date_range.min - 18.years)
    end
    memoize :dob_range_1

    # BH CP enrollees 18 to 64 years of age as of December 31st of the measurement year.
    def dob_range_2
      (dec_31_of_measurement_year - 64.years) .. (dec_31_of_measurement_year - 18.years)
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
        :id,
        :member_id,
        :date_of_birth,
      ).index_by(&:member_id)

      logger.debug { "#{members_by_member_id.size} members" }

      enrollments_by_member_id = assigned_enrollements_scope.select(
        :id,
        :member_id,
        :span_start_date,
        :span_end_date,
        :span_mem_days,
        :cp_enroll_dt,
        :cp_disenroll_dt,
        :cp_stop_rsn,
      ).group_by(&:member_id)

      logger.debug { "#{assigned_enrollements_scope.count} enrollment spans" }

      rows = []

      medical_claims_by_member_id = medical_claims_scope.select(
        :id,
        :member_id,
        :claim_number,
        #:cp_pidsl,
        :servicing_provider_type,
        :billing_provider_type,
        :service_start_date,
        :member_dob,
        :claim_type,
        :claim_status,
        :admit_date,
        :discharge_date,
        :revenue_code,
        :procedure_code,
        :procedure_modifier_1,
        :procedure_modifier_2,
        :procedure_modifier_3,
        :procedure_modifier_4,
        :enrolled_days,
      ).group_by(&:member_id)

      logger.debug { "#{medical_claims_scope.count} medical_claims" }

      pb = ProgressBar.create(total: medical_claims_by_member_id.size, format: '%c/%C (%P%%) %R/s%e [%B]')
      rows = Parallel.flat_map(
        medical_claims_by_member_id,
        finish: ->(_item, _i, _result) { pb.increment },
      ) do |member_id, claims|
        rows = []
        member = members_by_member_id[member_id]
        date_of_birth = member.date_of_birth
        enrollments = enrollments_by_member_id[member_id]
        assignment_date = enrollments.min_by(&:cp_enroll_dt).cp_enroll_dt
        completed_treatment_plans = claims.select(&:completed_treatment_plan?)

        # Members must be continuously enrolled in MassHealth during the measurement year.
        continuous_in_masshealth = continuously_enrolled_mh?(enrollments, measurement_year, max_gap: 45)

        # Members must be continuously enrolled in the BH CP for at least 122 calendar days.
        continuous_in_bh_cp = continuously_enrolled_cp?(enrollments, measurement_year, min_days: 122)

        rows << MeasureRow.new(
          row_type: 'member', # spec also says "patients"/"enrollee"
          row_id: member_id,
        ).tap do |row|
          row.medical_claims = claims.count

          # BH CP #1 The percentage of Behavioral Health Community Partner (BH CP)
          # assigned enrollees 18 to 64 years of age with documentation of engagement
          # within 122 days of the date of assignment to a BH CP.
          if dob_range_1.cover?(date_of_birth)
            cut_off_date = assignment_date + 122.days
            row.bh_cp_1 = completed_treatment_plans.any? { |c| c.service_start_date <= cut_off_date }
          end

          # BH CP #2: The percentage of Behavioral Health Community Partner (BH CP) enrollees
          # 18 to 64 years of age with documentation of a completed Treatment Plan during the
          # measurement year.
          # anchor_date = dob_range_2.max
          if continuous_in_bh_cp && continuous_in_masshealth && dob_range_2.cover?(date_of_birth)
            # Qualifying numerator activity does not need to occur during the 122-day continuous enrollment
            # period, and it can take place any time during the measurement year.
            row.bh_cp_2 = completed_treatment_plans.any? { |c| measurement_year.cover?(c.service_start_date) }
          end
        end

        # a member can have multiple discharges
        rows.concat calculate_bh_cp_3(member, claims, enrollments)

        # a member can have multiple ed visits
        rows.concat calculate_bh_cp_4(member, claims, enrollments)

        # a member can have multiple ed visits
        rows.concat calculate_bh_cp_5(member, claims, enrollments)
      end

      rows
    end
    memoize :medical_claim_based_rows

    # Do the enrollments indicate continuous enrollment in a Community Partner
    private def continuously_enrolled_cp?(enrollments, date_range, min_days: nil)
      # TODO: handle note from BH_CP_1
      # > The entity who submitted the documentation must be the same CP as the one that a member
      # > is enrolled with on the anchor date and during the 122-day continuous enrollment period.

      # TODO: handle the note from BH_CP_5
      # > Note: the initial benchmark performance period is 7/1/2018 – 6/30/2019.
      # > CP enrollees with no disenrollment, i.e., anchored on 6/30/2019,
      # > must have continuous MassHealth enrollment going back to 7/1/2018.)

      # find a enrollment with a Community Partner enrollment covering the end of the date_range
      latest_enrollment = enrollments.reverse.detect { |e| e.cp_enrolled_date_range&.cover?(date_range.max) }

      # none? -- then they arent continuous
      return false unless latest_enrollment

      # if it must be a minimum number of days than just look for that
      if min_days
        latest_enrollment && latest_enrollment.cp_enrolled_days >= min_days
      # otherwise check to see if they also had a Community Partner enrollment at the start
      else
        earliest_enrollment = enrollments.detect { |e| e.cp_enrolled_date_range&.cover?(date_range.min) }
        earliest_enrollment && latest_enrollment
      end
    end

    private def continuously_enrolled_mh?(enrollments, date_range, max_gap: 0)
      enrollments = enrollments.select { |e| e.span_date_range.overlaps?(date_range) }.sort

      enrollments.each_cons(2) do |e_prev, e|
        if (e.span_start_date - e_prev.span_end_date) > max_gap
          logger.debug { "Found enrollment gap > #{max_gap} #{e_prev.span_end_date.inspect}..#{e.span_start_date.inspect}" }
          return false
        end
      end
      true
    end

    private def in_age_range?(dob, range, as_of:)
      return nil unless dob && as_of # dob and as_of can both be nil in all callers, range should always be present

      dob.between?(as_of - range.max, as_of - range.min)
    end

    private def acute_inpatient_hospital?(_claim)
      # TODO: We need get a lookup of "Acute Inpatient Hospital IDs"
      # from somewhere
      false
    end

    private def cp_followup?(claim)
      # > Qualifying Activity: Follow up after Discharge submitted by the BH CP to the Medicaid Management
      # > Information System (MMIS) and identified via code G9007 with a U5 modifier. In addition to the
      # > U5 modifier...
      # FIXME?: Note sure if we need to check for U1/U2 or not, nor how to check for "comprised of a face-to-face visit"
      # > ...the following modifiers may be included: U1 or U2. This follow-up must be
      # > comprised of a face-to-face visit with the enrollee.)
      claim.procedure_code == 'G9007' && claim.modifiers.include?('U5')
    end

    private def declined_to_engage?(enrollments)
      # The reason for dis-enrollment from the BH CP will be identified as
      # Stop Reason “Declined” in the Medicaid Management Information System (MMIS).
      #
      # Note: This is never populated in data we've seen as of Apr 2021
      enrollments.any? { |e| e.cp_stop_rsn == 'Declined' }
    end

    private def measurement_year
      # FIXME: this is an abstraction, in an attempt to support
      # arbitrary date ranges. It is probably not reasonable to try.
      # Several places mention "September" or "December" of the [prior] measurement_year
      # so we need to deal with that offset. also the there is a lookup table for 2018,2019 years
      # that uses different offsets, half years etc
      date_range.max.beginning_of_year .. date_range.max.end_of_year
    end

    def dec_31_of_measurement_year
      measurement_year.max
    end

    private def assert_business_time
      # Business days are defined as Monday through Friday, even
      # if one or more of those days is a state or federal holiday.
      assert 'invalid BusinessTime::Config.work_week', BusinessTime::Config.work_week == ['mon', 'tue', 'wed', 'thu', 'fri']
      assert 'invalid BusinessTime::Config.holidays', BusinessTime::Config.holidays.empty?
    end

    # BH CP Quality Measurement Program BH CP #3: Follow-up with BH CP after acute or post- acute stay (3 business days)
    private def calculate_bh_cp_3(_member, claims, enrollments)
      assert_business_time

      # > Exclude: Members who decline to engage with the BH CP.
      return [] if declined_to_engage?(enrollments)

      servicing_provider_types = ['70', '71', '73', '74', '09', '26', '28']
      billing_provider_type = ['6', '3', '246', '248', '20', '21', '30', '31', '22', '332']

      billing_provider_type2 = ['1', '40', '301', '25']
      servicing_provider_types2 = ['35']

      # "on or between January 1 and more than 3 business days before the end of the measurement year."
      discharge_date_range = measurement_year.min .. 3.business_days.before(measurement_year.max)

      rows = []

      # Avoid O(n^2) by finding the small set of dates containing the claims
      # we will need to look for near each discharge
      admit_dates = Set.new
      eligable_followups = Set.new
      claims.each do |c|
        # > Exclude discharges followed by readmission or direct transfer to a
        # > facility setting within the 3- business-day follow-up period. To
        # > identify readmissions and direct transfers to a facility setting:
        # > 1. Identify all inpatient stays.
        # Note the spec does not reference the Inpatient Stay Value Set like it does for bh_cp_4
        # > 2. Identify the admission date for the stay.
        # > These discharges are excluded from the measure because a readmission
        # > or direct transfer may prevent a follow-up from taking place.
        admit_dates << c.admit_date if c.admit_date
        eligable_followups << c.service_start_date if c.service_start_date && cp_followup?(c)
      end

      claims.each do |c|
        next unless c.discharge_date && discharge_date_range.cover?(c.discharge_date)

        # Age: "BH CP enrollees 18 to 64 years of age as of date of discharge.""
        next unless in_age_range?(c.member_dob, 18.years .. 64.years, as_of: c.discharge_date)

        # Event/Diagnosis: A discharge from any facility setting listed below"
        next unless (
          c.servicing_provider_type.in?(servicing_provider_types) ||
          c.billing_provider_type.in?(billing_provider_type) ||
          (acute_inpatient_hospital?(c) && c.billing_provider_type.in?(billing_provider_type2))
        ) || (
          c.claim_type == 'inpatient' && c.servicing_provider_type.in?(servicing_provider_types2)
        )

        # Continuous Enrollment/Allowable Gap/Anchor Date/Exclusions:
        # Continuously enrolled with BH CP from date of discharge through 3 business days after discharge.
        # No allowable gap in BH CP enrollment during the continuous enrollment period."
        followup_period = (c.discharge_date .. 3.business_days.after(c.discharge_date)).to_a
        next unless continuously_enrolled_cp?(enrollments, followup_period)

        # exclude readmitted
        next if (admit_dates & followup_period).any?

        # count in the numerator if we had a eligable_followups in the period
        eligable_followup = (eligable_followups & followup_period).any?

        row = MeasureRow.new(
          row_type: 'stay',
          row_id: c.id,
          bh_cp_3: eligable_followup,
        )
        # puts "Found #{row.inspect}"

        rows << row
      end
      rows
    end

    private def value_set_codes(name, code_system)
      codes = Hl7::ValueSetCode.where(
        value_set_oid: VALUE_SETS.fetch(name),
        code_system: code_system,
      ).pluck(:code).to_set

      assert "#{name} Value Set must contain some codes for #{code_system}", codes.present?

      codes
    end
    memoize :value_set_codes

    private def ed_visit?(claim)
      value_set_codes('ED', PROCEDURE_CODE_SYSTEMS).include? claim.procedure_code
    end

    private def inpatient_stay?(claim)
      value_set_codes('Inpatient Stay', REVENUE_CODE_SYSTEMS).include? claim.revenue_code
    end

    private def assert(explaination, condition)
      raise explaination unless condition
    end

    private def trace_exclusion(&block)
      # logger.debug &block
    end

    # Follow-up with BH CP after Emergency Department visit
    private def calculate_bh_cp_4(_member, claims, enrollments)
      # "on or between January 1 and December 1 of the measurement year."
      visit_date_range = measurement_year

      # > Also Exclude: Members who decline to engage with the BH CP.
      return [] if declined_to_engage?(enrollments)

      ed_visits = []
      claims.select do |c|
        next unless c.discharge_date && ed_visit?(c) && visit_date_range.cover?(c.service_start_date)

        visit_date = c.discharge_date
        assert 'ED visit must have a discharge_date', c.discharge_date.present?

        # "BH CP enrollees 18 to 64 years of age as of date of ED visit."
        unless in_age_range?(c.member_dob, 18.years .. 64.years, as_of: visit_date)
          trace_exclusion do
            "BH_CP_4: Exclude claim #{c.id}: DOB: #{c.member_dob} outside age range as of #{visit_date}"
          end
          next
        end

        # "Continuously enrolled with BH CP from date of ED visit through 7 calendar
        # days after ED visit (8 total days). There is no requirement for MassHealth enrollment."
        followup_period = (visit_date .. 7.days.after(visit_date)).to_a
        assert "followup_period must be 8 days, was #{followup_period.size} days.", followup_period.size == 8

        unless continuously_enrolled_cp?(enrollments, followup_period)
          trace_exclusion do
            "BH_CP_4: Exclude claim #{c.id}: not continuously_enrolled_in_cp during #{followup_period.min .. followup_period.max}"
          end
          next
        end

        # "An ED visit (ED Value Set) on or between January 1 and December 1 of the measurement year."
        ed_visits << c
      end

      # TODO: If a member has more than one ED visit in an 8-day period, include
      # only the first ED visit. For example, if a member has an ED visit on
      # January 1 then include the January 1 visit and do not include ED
      # visits that occur on or between January 2 and January 8; then, if
      # applicable, include the next ED visit that occurs on or after January
      # 9. Identify visits chronologically including only one per 8-day
      # period.

      # Avoid O(n^2) by finding the small set of dates containing the claims
      # we will need to look for near each discharge
      inpatient_stay_dates = Set.new
      eligable_followups = Set.new
      claims.select do |c|
        # To identify admissions to an acute or nonacute inpatient care setting:
        # 1. Identify all acute and nonacute inpatient stays (Inpatient Stay
        # Value Set).
        # 2. Identify the admission date for the stay.
        # An ED visit billed on the same claim as an inpatient stay is
        # considered a visit that resulted in an inpatient stay.
        inpatient_stay_dates << c.admit_date if c.admit_date && inpatient_stay?(c) && ed_visits.none? { |v| v.claim_number == c.claim_number }

        # These events are excluded from the measure because admission to an
        # acute or nonacute inpatient setting may prevent an outpatient
        # follow-up visit from taking place.

        eligable_followups << c.service_start_date if cp_followup?(c)
      end
      # puts inpatient_stay_dates if inpatient_stay_dates.any?
      # puts eligable_followups if eligable_followups.any?

      rows = []
      ed_visits.each do |c|
        visit_date = c.discharge_date
        followup_period = (visit_date .. 7.days.after(visit_date)).to_a

        # Exclude ED visits followed by admission to an acute or nonacute
        # inpatient care setting on the date of the ED visit or within 7
        # calendar days after the ED visit (8 total days), regardless of
        # principal diagnosis for the admission.
        if (admits = (inpatient_stay_dates & followup_period)).any?
          trace_exclusion do
            "BH_CP_4: Exclude claim #{c.id}: inpatient admitted too soon #{admits.to_a}"
          end
          next
        end

        # Discharges for enrollees with the following supports within 7 calendar days of discharge from an ED; include supports that occur on the date of discharge.
        eligable_followup = (eligable_followups & followup_period).any?

        row = MeasureRow.new(
          row_type: 'visit',
          row_id: c.id,
          bh_cp_4: eligable_followup,
        )
        # puts "Found #{row.inspect}" if row.bh_cp_4

        rows << row
      end
      rows
    end

    private def pcp_practitioner?(_claim)
      # TODO
      false
    end

    private def ob_gyn_practitioner?(_claim)
      # TODO
      false
    end

    private def hospice?(claim)
      (
        claim.procedure_code.in?(value_set_codes('Hospice', PROCEDURE_CODE_SYSTEMS)) ||
        claim.revenue_code.in?(value_set_codes('Hospice', REVENUE_CODE_SYSTEMS))
      )
    end

    private def in_set?(value_set, claim)
      # TODO
    end

    private def aod_dx?(claim)
      in_set?('AOD Abuse and Dependence', claim) || in_set?('AOD Medication', claim)
    end

    private def aod_rx?(rx_claim)
      (
        in_set?('Medication Treatment for Alcohol Abuse or Dependence Medications List', rx_claim) ||
        in_set?('Medication Treatment for Opioid Abuse or Dependence Medications List', rx_claim)
      )
    end

    private def aod_abuse_or_dependence?(claim)
      # New episode of AOD abuse or dependence
      # FIXME this may need to be evaluated on
      # all the claims in the same 'stay' TODO
      # this is used to find a IESD

      c = claim
      aod_abuse = (
        in_set?('Alcohol Abuse and Dependence', c) ||
        in_set?('Opioid Abuse and Dependence', c) ||
        in_set?('Other Drug Abuse and Dependence', c)
      ) # && value_set_codes('Telehealth Modifier Value', PROCEDURE_CODE_SYSTEMS)

      (
        in_set?('IET Stand Alone', c) && aod_abuse
      ) || (
        in_set?('IET Visits Group 1', c) && in_set?('IET POS Group 1', c) && aod_abuse
      ) || (
        in_set?('IET Visits Group 2', c) && in_set?('IET POS Group 2', c) && aod_abuse
      ) || (
        in_set?('IET Detoxification', c) && aod_abuse
      ) || (
        in_set?('ED', c) && aod_abuse
      ) || (
        in_set?('Observation', c) && aod_abuse
      ) || (
        inpatient_stay?(c) && aod_abuse
      ) || (
        in_set?('Telephone Visits', c) && aod_abuse
      ) || (
        in_set?('Online Assessments', c) && aod_abuse
      )
    end

    private def annual_primary_care_visit?(claim)
      # ... comprehensive physical examination (Well-Care Value
      # Set, or any of the following procedure codes: 99386, 99387, 99396,
      # 99397 [CPT]; T1015 [HCPCS]) with a PCP or an OB/GYN practitioner
      # (Provider Type Definition Workbook). The practitioner does not have to
      # be the practitioner assigned to the member. The comprehensive
      # well-care visit can happen any time during the measurement year; it
      # does not need to occur during a CP enrollment period.
      (
        claim.procedure_code.in?(value_set_codes('Well-Care', PROCEDURE_CODE_SYSTEMS)) ||
        (claim.procedure_code.in?(APC_EXTRA_PROC_CODES) && (pcp_practitioner?(claim) || ob_gyn_practitioner?(claim)))
      )
    end

    # Annual Primary Care Visit
    private def calculate_bh_cp_5(member, claims, enrollments)
      # > BH CP enrollees 18 to 64 years of age as of December 31 of the measurement year.
      return [] unless in_age_range?(member.date_of_birth, 18.years .. 64.years, as_of: dec_31_of_measurement_year)

      # > Exclusions: Enrollees in Hospice (Hospice Value Set)
      if claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
        trace_exclusion do
          "BH_CP_5: Exclude MemberRoster#id=#{member.id} is in hospice"
        end
        return []
      end

      # > For members continuously enrolled with the CP for at least 122 days,
      # > and with no CP disenrollment during the measurement year (note that
      # > this scenario logically implies an enrollment anchor on the last day
      # > of the measurement period),
      # ....
      # > For members with one or more disenrollments during the measurement
      # > year, identify each enrollment segment with the CP provider of 122
      # > days or longer that ends in a disenrollment. Identify the
      # > disenrollment date for each of these segments. (Note: each
      # > disenrollment date is a separate event to be evaluated, establishing
      # > an anchor date for claims lookback. This is true regardless of whether
      # > the multiple enrollment segments are with the same, or different, CP

      # Both handled by....
      disenrollments = enrollments.select do |e|
        e.cp_enroll_dt.present? && measurement_year.cover?(e.cp_enroll_dt)
      end
      claim_date_ranges = if disenrollments.any?
        disenrollments.map do |e|
          (e.cp_enroll_dt - 1.year) .. e.cp_enroll_dt
        end
      elsif continuously_enrolled_cp?(enrollments, measurement_year, min_days: 122)
        [measurement_year]
      else
        []
      end

      # > [a primary care visit] must occur during the date range[s] above
      rows = []
      claim_date_ranges.each do |date_range|
        pcp_visit = claims.detect do |c|
          date_range.cover?(c.service_start_date) && annual_primary_care_visit?(c)
        end

        rows << MeasureRow.new(
          row_type: 'enrollee',
          row_id: "#{member.id}/#{date_range}/#{pcp_visit&.service_start_date}",
          bh_cp_5: pcp_visit.present?,
        )
      end
      rows
    end

    def assigned_enrollees
      formatter.format_i assigned_enrollements_scope.distinct.count(:member_id)
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
      percentage medical_claim_based_rows, :bh_cp_4
    end

    def bh_cp_5
      percentage medical_claim_based_rows, :bh_cp_5
    end

    def bh_cp_6
      percentage medical_claim_based_rows, :bh_cp_6
    end

    def bh_cp_7
      percentage medical_claim_based_rows, :bh_cp_7
    end

    def bh_cp_8
      percentage medical_claim_based_rows, :bh_cp_8
    end

    def bh_cp_9
      percentage medical_claim_based_rows, :bh_cp_9
    end

    def bh_cp_10
      percentage medical_claim_based_rows, :bh_cp_10
    end

    def bh_cp_11
      percentage medical_claim_based_rows, :bh_cp_11
    end

    def bh_cp_13
      percentage medical_claim_based_rows, :bh_cp_13
    end

    # Map the names used in HEDIS QRS and the Quality Metrics spec
    # to the OIDs. Not needed now but names will not be unique in
    # Hl7::ValueSetCode as we flesh that out
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
  end
end
