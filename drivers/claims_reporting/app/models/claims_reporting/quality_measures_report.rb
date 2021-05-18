# frozen_string_literal: true

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memoist'

# Calculator for various Quality Measures in the MassHealth Community Partners (CP) Program
# https://www.mass.gov/guides/masshealth-community-partners-cp-program-information-for-providers
module ClaimsReporting
  class QualityMeasuresReport
    include ActiveModel::Model
    include HmisFilters
    extend Memoist

    # Base Range<Date> for this report. Some measures define derived ranges
    attr_reader :date_range

    # The Measure#id s we want to calculate. Defaults to all AVAILABLE_MEASURES.keys
    attr_reader :measures

    # An optional ::Filters::QualityMeasuresFilter to apply to the data.
    attr_reader :filter

    # This report is normally run against a plan year...
    def self.for_plan_year(year, **options)
      year = year.to_i
      new(
        date_range: Date.new(year.to_i, 1, 1) .. Date.new(year.to_i, 12, 31),
        **options,
      )
    end

    def initialize(
      date_range:,
      filter: nil,
      measures: nil
    )
      filter ||= ::Filters::QualityMeasuresFilter.new
      raise ArgumentError, 'filter must be a ::Filters::QualityMeasuresFilter' unless filter.is_a? ::Filters::QualityMeasuresFilter

      @filter = filter
      @date_range = date_range

      # which measures will we calculate
      @measures = if measures
        AVAILABLE_MEASURES.keys & measures
      else
        AVAILABLE_MEASURES.keys
      end

      raise ArgumentError, 'No valid measures provided' if @measures.none?
    end

    Measure = Struct.new(:id, :title, :desc, :numerator, :denominator, keyword_init: true)
    AVAILABLE_MEASURES = [
      Measure.new(
        id: :bh_cp_1,
        title: 'BH CP #1: Community Partner Engagement (122 days) - % patients',
        desc: <<~MD,
          The percentage of Behavioral Health Community Partner (BH CP) assigned enrollees 18 to 64 years of age with documentation of engagement within 122 days of the date of assignment to a BH CP.
        MD
        numerator: 'BH CP assigned enrollees 18 to 64 years of age who had documentation of engagement within 122 days of the date of assignment.',
        denominator: 'BH CP assigned enrollees 18 to 64 years of age as of December 31st of the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_2,
        title: 'BH CP #2: Annual Treatment Plan Completion - % patients',
        desc: <<~MD,
          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with documentation of a completed Treatment Plan during the measurement year.

          Members must be:

          * Continuously enrolled in the BH CP for at least 122 calendar days.
          * Continuously enrolled in MassHealth during the measurement year. A gap is allowed of up to 45 days.
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age who had documentation of a completed Treatment Plan during the measurement year. Treatment plan must be completed by the CP with whom the member met continuous enrollment requirement',
        denominator: 'BH CP enrollees 18 to 64 years of age as of December 31st of the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_3,
        title: 'BH CP #3: Follow-up with BH CP after acute or post-acute stay (3 business days) - % stays',
        desc: <<~MD,
          The percentage of discharges from acute or post-acute stays for Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age that were succeeded by a follow-up with the BH CP within 3 business days of discharge.

          Members must be:

          * Continuously enrolled with BH CP from date of discharge through 3 business days after discharge.
          * There is no requirement for MassHealth enrollment.

          Excludes discharges followed by readmission or direct transfer to a facility setting within the 3- business-day follow-up period.
        MD
        numerator: 'Discharges for BH CP enrollees 18 to 64 years of age that were succeeded by a follow-up with the BH CP within 3 business days of discharge.',
        denominator: 'Discharges for BH CP enrollees 18 to 64 years of age during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_4,
        title: 'BH CP #4: Follow-up with BH CP after Emergency Department visit - % visits',
        desc: <<~MD,
          The percentage of emergency department (ED) visits for Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age that had a follow-up visit within 7 calendar days of the ED visit.

          Members must be:

          * Continuously enrolled with BH CP from date of ED visit through 7 calendar days after ED visit (8 total days).
          * There is no requirement for MassHealth enrollment.

          If a member has more than one ED visit in an 8-day period, include only the first ED visit.

          Excludes ED visits followed by admission to an acute or nonacute inpatient care setting on the date of the ED visit or within 7 calendar days after the ED visit (8 total days),
          regardless of principal diagnosis for the admission.
        MD
        numerator: 'Discharges from the ED for BH CP enrollees 18 to 64 years of age that were succeeded by a follow-up with the BH CP within 7 calendar days after discharge.',
        denominator: 'Discharges from the ED for BH CP enrollees 18 to 64 years of age during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_5,
        title: 'BH CP #5: Annual Primary Care Visit - % patients',
        desc: <<~MD,
          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age who had at least one comprehensive well-care visit with a PCP or an OB/GYN practitioner during the measurement year.

          Continous Enrollment requirements:

          * BH CP enrollees without a CP disenrollment during the measurement year must be continuously enrolled in MassHealth during the measurement year.
          * BH CP enrollees with a CP disenrollment during the measurement year must be continuously enrolled in MassHealth for one year prior to the disenrollment date.
          * BH CP enrollees must be continuously enrolled in a BH CP for at least 122 calendar days during the measurement year.
          * A gap of no more than 45 calendar days during periods of continuous MassHealth enrollment.

          Excludes enrollees in Hospice durring the measurement year.
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age who received a comprehensive well-care visit at least one time during the measurement year.',
        denominator: 'BH CP enrollees 18 to 64 years of age as of December 31 of the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_6,
        title: 'BH CP #6: Community Tenure - % eligible days',
        desc: 'The percentage of eligible days that BH CP assigned members 21 to 64 years of age reside in their home or in a community setting without utilizing acute, chronic, or post- acute institutional health care services during the measurement year.',
        numerator: 'The sum of eligible days that BH CP assigned members 21 to 64 years of age reside in their home or in a community without utilizing acute, chronic, or post-acute institutional health care services during the measurement year.',
        denominator: 'The sum of eligible days of members that are enrolled in a BH CP during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_7,
        title: 'BH CP #7: Initiation of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
        desc: <<~MD,
          <mark>**Note**: This measure requires AOD claims data which are currently not available.</mark>

          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with a new episode of alcohol, opioid,
          or other drug (AOD) abuse or dependence who received the following.

          - Initiation of AOD Treatment. The percentage of enrollees who initiate treatment through an inpatient AOD admission,
            outpatient visit, intensive outpatient encounter or partial hospitalization, telehealth or medication assisted treatment
            (medication treatment) within 14 days of the diagnosis.
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age who initiate/engage with AOD treatment.',
        denominator: 'BH CP enrollees 18 to 64 years of age with a new episode of AOD during the intake period.',
      ),
      Measure.new(
        id: :bh_cp_8,
        title: 'BH CP #8: Engagement of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
        desc: <<~MD,
          <mark>**Note**: This measure requires AOD claims data which are currently not available.</mark>

          The percentage of Behavioral Health Community Partner (BH CP) enrollees 18 to 64 years of age with a new episode of alcohol, opioid,
          or other drug (AOD) abuse or dependence who received the following.

          - Engagement of AOD Treatment. The percentage of enrollees who initiated treatment and who had two or more additional
            AOD services or medication treatment within 34 days of the initiation visit.
        MD
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
        id: :bh_cp_12,
        title: 'BH CP #12: Emergency Department Visits for Adults with Mental Illness, Addiction, or Co-occurring Conditions',
        desc: <<~MD,
          <mark>**Note**: This measure requires AOD claims data which are currently not available.</mark>
        MD
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

    private def logger
      Rails.logger
    end

    PROCEDURE_CODE_SYSTEMS = ['HCPCS', 'CPT', 'CPT-CAT-II'].freeze
    REVENUE_CODE_SYSTEMS = ['UBREV'].freeze
    APC_EXTRA_PROC_CODES = ['99386', '99387', '99396', '99397', 'T1015'].freeze

    # we are keeping rows of each enrollee, etc and flags for each measure
    # with three possible values:
    #  - nil (not in the universe for the measure)
    #  - false part of the denominator only
    #  - true part of the numerator
    MeasureRow = Struct.new(:row_type, :row_id, *AVAILABLE_MEASURES.keys, keyword_init: true)

    def serializable_hash
      measure_info = AVAILABLE_MEASURES.values.map do |m|
        numerator, denominator = *send(m.id)
        # only one value indicates a count
        if denominator.present?
          value = (numerator.to_f / denominator) unless denominator.zero?
        else
          value = numerator
          numerator = nil
        end
        [m.id, {
          id: m.id,
          title: m.title,
          numerator: numerator,
          denominator: denominator,
          value: value,
        }]
      end.to_h

      {
        date_range: date_range,
        filter: filter.serializable_hash,
        measures: measure_info,
      }
    end
    memoize :serializable_hash

    def measure_value(measure)
      serializable_hash[:measures][measure.to_sym]
    end

    memoize :hud_clients_scope

    def warehouse_client_scope
      hmis_scope = ::GrdaWarehouse::DataSource.joins(:clients)
      hmis_scope = filter_for_gender(hmis_scope) if filter.genders.present?
      hmis_scope = filter_for_race(hmis_scope) if filter.races.present?
      hmis_scope = filter_for_ethnicity(hmis_scope) if filter.ethnicities.present?
      hmis_scope
    end
    memoize :warehouse_client_scope

    # BH CP assigned enrollees 18 to 64 years of age as of December 31st of the measurement year.
    def assigned_enrollements_scope
      scope = ::ClaimsReporting::MemberEnrollmentRoster

      # hud client properties
      scope = scope.joins(:patient).merge(::Health::Patient.where(client_id: hud_clients_scope.ids)) if filtered_by_client?

      # and via patient referral data
      scope = scope.joins(patient: :patient_referral).merge(::Health::PatientReferral.at_acos(filter.acos)) if filter.acos.present?

      # age
      scope = filter_for_age(scope, as_of: date_range.min)

      e_t = scope.quoted_table_name
      # TODO: handle "September"
      # Members assigned to a BH CP on or between September 2nd of the year prior to the
      # measurement year and September 1st of the measurement year.
      scope = scope.where(
        ["#{e_t}.cp_enroll_dt <= :max and (#{e_t}.cp_disenroll_dt IS NULL OR #{e_t}.cp_disenroll_dt > :max)", {
          min: date_range.min,
          max: date_range.max,
        }],
      )
      scope.where(
        member_id: ::ClaimsReporting::MemberRoster.where(date_of_birth: dob_range_1).select(:member_id),
      )
      scope
    end
    memoize :assigned_enrollements_scope

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
        :cp_pidsl,
        :cp_enroll_dt,
        :cp_disenroll_dt,
        :cp_stop_rsn,
      ).group_by(&:member_id)

      logger.debug { "#{assigned_enrollements_scope.count} enrollment spans" }

      rows = []

      medical_claims_by_member_id = medical_claims_scope.select(
        :id,
        :member_id,
        :member_dob,
        :claim_number, # "billed on the same claim"
        :cp_pidsl, # "same CP"
        :servicing_provider_type,
        :service_provider_npi, # only "used" by bh_cp_6
        :billing_provider_type,
        :billing_npi, # only "used" by bh_cp_6
        :service_start_date,
        :service_end_date,
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
        :place_of_service_code,
        :type_of_bill,
        :icd_version,
        :dx_1, :dx_2, :dx_3, :dx_4, :dx_5, :dx_6, :dx_7, :dx_8, :dx_9, :dx_10,
        :dx_11, :dx_12, :dx_13, :dx_14, :dx_15, :dx_16, :dx_17, :dx_18, :dx_19, :dx_20,
        :surgical_procedure_code_1,
        :surgical_procedure_code_2,
        :surgical_procedure_code_3,
        :surgical_procedure_code_4,
        :surgical_procedure_code_5,
        :enrolled_days
      ).group_by(&:member_id)

      logger.debug { "#{medical_claims_scope.count} medical_claims" }

      # pb = ProgressBar.create(total: medical_claims_by_member_id.size, format: '%c/%C (%P%%) %R/s%e [%B]')
      rows = Parallel.flat_map(
        medical_claims_by_member_id,
        in_processes: 1,
        # finish: ->(_item, _i, _result) { pb.increment },
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

        if measures.include?(:bh_cp_1) || measures.include?(:bh_cp_2)
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
        end

        rows.concat calculate_bh_cp_3(member, claims, enrollments) if measures.include?(:bh_cp_3)
        rows.concat calculate_bh_cp_4(member, claims, enrollments) if measures.include?(:bh_cp_4)
        rows.concat calculate_bh_cp_5(member, claims, enrollments) if measures.include?(:bh_cp_5)
        rows.concat calculate_bh_cp_6(member, claims, enrollments) if measures.include?(:bh_cp_6)

        # We dont have data to support this yet
        # rows.concat calculate_bh_cp_7(member, claims, enrollments) if measures.include?(:bh_cp_7)
        # rows.concat calculate_bh_cp_8(member, claims, enrollments) if measures.include?(:bh_cp_8)

        # rows.concat calculate_bh_cp_9(member, claims, enrollments) if measures.include?(:bh_cp_9)

        rows
      end
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

      # TODO: no measure allows for gaps in CP enrollment
      # if we find any than this is not a "continuous enrollment"

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

    private def in_set?(vs_name, claim)
      codes_by_system = value_set_lookups.fetch(vs_name)

      # TODO?: Can we use LOINC (labs) or CVX (vaccine) codes
      # What about "Modifier"

      # Check first because its very likely to match
      procedure_codes = Set.new
      PROCEDURE_CODE_SYSTEMS.each do |code_system|
        procedure_codes |= codes_by_system[code_system] if codes_by_system[code_system]
      end
      return trace_set_match!(vs_name, claim, PROCEDURE_CODE_SYSTEMS) if procedure_codes.include?(claim.procedure_code)

      # Check easy ones next
      if (revenue_codes = codes_by_system['UBREV']).present?
        return trace_set_match!(vs_name, claim, :UBREV) if revenue_codes.include?(claim.revenue_code)
      end

      # https://www.findacode.com/articles/type-of-bill-table-34325.html
      if (bill_types = codes_by_system['UBTOB']).present?
        return trace_set_match!(vs_name, claim, :UBTOB) if bill_types.include?(claim.type_of_bill)
      end

      if (place_of_service_codes = codes_by_system['POS'])
        return trace_set_match!(vs_name, claim, :POS) if place_of_service_codes.include?(claim.place_of_service_code)
      end

      # Slower set intersection ones, current ICD version
      if (code_pattern = codes_by_system['ICD10CM'])
        return trace_set_match!(vs_name, claim, :ICD10CM) if claim.matches_icd10cm? code_pattern
      end
      if (code_pattern = codes_by_system['ICD10PCS'])
        return trace_set_match!(vs_name, claim, :ICD10PCS) if claim.matches_icd10pcs? code_pattern
      end

      # Slow and rare
      if (code_pattern = codes_by_system['ICD9CM'])
        return trace_set_match!(vs_name, claim, :ICD9CM) if claim.matches_icd9cm? code_pattern
      end

      if (code_pattern = codes_by_system['ICD9PCS']) # rubocop:disable Style/GuardClause
        return trace_set_match!(vs_name, claim, :ICD9PCS) if claim.matches_icd9pcs? code_pattern
      end
    end

    # efficiently loads, caches, returns
    # a 2-level lookup table: value_set_name -> code_system_name -> Set<codes> | RegExp
    def value_set_lookups
      sets = VALUE_SETS.keys.map do |vs_name|
        [vs_name, {}]
      end.to_h

      oid_to_name = VALUE_SETS.invert
      rows = Hl7::ValueSetCode.where(
        value_set_oid: VALUE_SETS.values,
      ).pluck(:value_set_oid, :code_system, :code)

      rows.each do |value_set_oid, code_system, code|
        vs_name = oid_to_name.fetch(value_set_oid)
        sets[vs_name][code_system] ||= []
        sets[vs_name][code_system] << code
      end

      lookup_table = {}

      sets.each do |vs_name, code_system_data|
        lookup_table[vs_name] = {}
        code_system_data.each do |code_system, codes|
          if code_system.in? ['ICD10CM', 'ICD10PCS', 'ICD9CM', 'ICD10PCS']
            # we don't generally have decimals in data
            codes = codes.map { |code| code.gsub('.', '') }
            lookup_table[vs_name][code_system] = Regexp.new "^(#{codes.join('|')})"
          elsif code_system.in? ['UBTOB', 'UBREV']
            # our claims data doesn't have leading zeros, it might in the future
            codes = codes.flat_map { |code| [code, code.gsub('^0', '')] }
            lookup_table[vs_name][code_system] = Set.new codes
          else
            lookup_table[vs_name][code_system] = Set.new codes
          end
        end
      end

      lookup_table.transform_values(&:freeze)
      lookup_table.freeze
    end
    memoize :value_set_lookups

    private def value_set_codes(name, code_systems)
      value_set_lookups.fetch(name.to_s).values_at(*Array(code_systems)).flatten.compact
    end
    memoize :value_set_codes

    private def ed_visit?(claim)
      in_set?('ED', claim)
    end

    private def inpatient_stay?(claim)
      in_set?('Inpatient Stay', claim)
    end

    private def assert(explaination, condition)
      raise explaination unless condition
    end

    private def trace_exclusion(&block)
      # hook to log exclusions
      logger.debug(&block)
    end

    # Follow-up with BH CP after Emergency Department visit
    private def calculate_bh_cp_4(member, claims, enrollments)
      # "on or between January 1 and December 1 of the measurement year."
      visit_date_range = measurement_year

      # > Also Exclude: Members who decline to engage with the BH CP.
      if declined_to_engage?(enrollments)
        trace_exclusion { "BH_CP_4: Exclude member #{member.id}: declined_to_engage" }
        return []
      end

      ed_visits = []
      claims.select do |c|
        next unless c.discharge_date && ed_visit?(c) && visit_date_range.cover?(c.service_start_date)

        visit_date = c.discharge_date
        assert 'ED visit must have a discharge_date', c.discharge_date.present?

        # "BH CP enrollees 18 to 64 years of age as of date of ED visit."
        unless in_age_range?(c.member_dob, 18.years .. 64.years, as_of: visit_date)
          trace_exclusion { "BH_CP_4: Exclude claim #{c.id}: DOB: #{c.member_dob} outside age range as of #{visit_date}" }
          next
        end

        # "Continuously enrolled with BH CP from date of ED visit through 7 calendar
        # days after ED visit (8 total days). There is no requirement for MassHealth enrollment."
        followup_period = (visit_date .. 7.days.after(visit_date)).to_a
        assert "followup_period must be 8 days, was #{followup_period.size} days.", followup_period.size == 8

        unless continuously_enrolled_cp?(enrollments, followup_period)
          trace_exclusion { "BH_CP_4: Exclude claim #{c.id}: not continuously_enrolled_in_cp during #{followup_period.min .. followup_period.max}" }
          next
        end

        # "An ED visit (ED Value Set) on or between January 1 and December 1 of the measurement year."
        ed_visits << c
      end

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

        # Discharges for enrollees with the following supports within 7 calendar days of
        # discharge from an ED; include supports that occur on the date of discharge.
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

    private def mental_health_hospitalization?(claim)
      (
        in_set?('Mental Illness', claim) || in_set?('Intentional Self-Harm', claim)
      ) && (
        inpatient_stay?(claim) && !in_set?('Nonacute Inpatient Stay', claim)
      )
    end

    #  Follow-Up After Hospitalization for Mental Illness (7 days)
    private def calculate_bh_cp_9(member, claims, enrollments)
      # > Exclusions: Enrollees in Hospice (Hospice Value Set)
      if claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
        trace_exclusion do
          "BH_CP_9: Exclude MemberRoster#id=#{member.id} is in hospice"
        end
        return []
      end

      # > Also Exclude: Members who decline to engage with the BH CP.
      return [] if declined_to_engage?(enrollments)

      discharges = []
      claims.select do |c|
        # > The denominator for this measure is based on discharges, not on enrollees.
        # > If enrollees have more than one discharge, include all discharges on or
        # > between January 1 and December 1 of the measurement year.
        next unless c.discharge_date && measurement_year.cover?(c.service_start_date) && mental_health_hospitalization?(c)

        puts "BH_CP_9: MemberRoster#id=#{member.id}. Found mental_health_hospitalization..."

        visit_date = c.discharge_date
        assert 'Mental health hospitalization visit must have a discharge_date', c.discharge_date.present?

        # > BH CP enrollees 18 to 64 years of age as of the date of discharge."
        unless in_age_range?(c.member_dob, 18.years .. 64.years, as_of: visit_date)
          trace_exclusion { "BH_CP_9: Exclude claim #{c.id}: DOB: #{c.member_dob} outside age range as of #{visit_date}" }
          next
        end

        # > Continuously enrolled with BH CP from date of discharge through 7
        # > calendar days after discharge. There is no requirement for MassHealth enrollment."
        followup_period = (visit_date .. 7.days.after(visit_date)).to_a
        assert "followup_period must be 8 days, was #{followup_period.size} days.", followup_period.size == 8

        # > No allowable gap in BH CP enrollment during the continuous enrollment period.
        unless continuously_enrolled_cp?(enrollments, followup_period)
          trace_exclusion { "BH_CP_9: Exclude claim #{c.id}: not continuously_enrolled_in_cp during #{followup_period.min .. followup_period.max}" }
          next
        end

        discharges << c
      end

      # TODO: handle readmissions and direct transfers to an acute inpatient
      # > Identify readmissions and direct transfers to an acute inpatient
      # > care setting during the 7-day follow-up period:
      # >  1. Identify all acute and nonacute inpatient stays (Inpatient Stay Value Set).
      # >   2. Exclude nonacute inpatient stays (Nonacute Inpatient Stay Value Set).
      # >   3. Identify the admission date for the stay.
      # > Exclude both the initial discharge and the readmission/direct transfer discharge
      # > if the last discharge occurs after December 1 of the measurement year.
      # >
      # > If the readmission/direct transfer to the acute inpatient care setting was for a
      # > principal diagnosis of mental health disorder or intentional self-harm
      # > (Mental Health Diagnosis Value count only the last discharge.
      # > If the readmission/direct transfer to the acute inpatient care setting was for
      # > any other principal diagnosis exclude both the original and the readmission/direct transfer discharge.
      # >
      # > Exclude discharges followed by readmission or direct transfer to a nonacute
      # > inpatient care setting within the 7-day follow-up period, regardless of
      # > principal diagnosis for the readmission. To identify readmissions and direct
      # > transfers to a nonacute inpatient care setting:
      # >   1. Identify all acute and nonacute inpatient stays (Inpatient Stay Value Set).
      # >   2. Confirm the stay was for nonacute care based on the presence of a nonacute code (Nonacute Inpatient Stay Value Set) on the claim.
      # >   3. Identify the admission date for the stay.
      # > These discharges are excluded from the measure because rehospitalization or
      # > direct transfer may prevent an outpatient follow-up visit from taking place.

      # Avoid O(n^2) by finding the small set of dates containing the claims
      # we will need to look for near each discharge
      inpatient_stay_dates = Set.new
      eligable_followups = Set.new
      claims.select do |c|
        # > A follow-up visit with a mental health practitioner within 7 days after
        # > discharge. Do not include visits that occur on the date of discharge.
        # > Any of the following meet criteria for a follow-up visit.

        inpatient_stay_dates << c.admit_date if c.admit_date && inpatient_stay?(c) && discharges.none? { |v| v.claim_number == c.claim_number }

        eligable_followups << c.service_start_date if cp_followup?(c)
      end
      # puts inpatient_stay_dates if inpatient_stay_dates.any?
      # puts eligable_followups if eligable_followups.any?

      rows = []
      discharges.each do |c|
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
      true
    end

    private def ob_gyn_practitioner?(_claim)
      # TODO
      true
    end

    private def hospice?(claim)
      (
        claim.procedure_code.in?(value_set_codes('Hospice', PROCEDURE_CODE_SYSTEMS)) ||
        claim.revenue_code.in?(value_set_codes('Hospice', REVENUE_CODE_SYSTEMS))
      )
    end

    private def trace_set_match!(_vs_name, _claim, _code_type)
      # puts "in_set? #{_vs_name} matched #{_code_type} for Claim#id=#{_claim.id}"
      true
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

      return false unless aod_abuse # we can bail no other condition can match

      raise 'FIXME: We have not had AOD data to date so the logic below has no real world testing' if aod_abuse

      # direct translation of the English spec
      (
        in_set?('IET Stand Alone Visits', c) && aod_abuse
      ) || (
        in_set?('IET Visits Group 1', c) && in_set?('IET POS Group 1', c) && aod_abuse
      ) || (
        in_set?('IET Visits Group 2', c) && in_set?('IET POS Group 2', c) && aod_abuse
      ) || (
        in_set?('Detoxification', c) && aod_abuse
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
        in_set?('Well-Care', claim) ||
        (claim.procedure_code.in?(APC_EXTRA_PROC_CODES) && (pcp_practitioner?(claim) || ob_gyn_practitioner?(claim)))
      )
    end

    # Annual Primary Care Visit
    private def calculate_bh_cp_5(member, claims, enrollments)
      # > BH CP enrollees 18 to 64 years of age as of December 31 of the measurement year.
      unless in_age_range?(member.date_of_birth, 18.years .. 64.years, as_of: dec_31_of_measurement_year)
        trace_exclusion do
          "BH_CP_5: Exclude MemberRoster#id=#{member.id} based on age"
        end
        return []
      end
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
      # puts "BH_CP_5: claim_date_ranges=#{claim_date_ranges}" if claim_date_ranges.any?

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

    # Community Tenure
    private def calculate_bh_cp_6(member, claims, enrollments)
      # > Age: Members who receive care from a Behavioral Health (BH) Community Partner (CP),
      # > 21 to 64 years of age as of December 31 of the measurement year.
      unless in_age_range?(member.date_of_birth, 21.years .. 64.years, as_of: dec_31_of_measurement_year)
        trace_exclusion { 'BH_CP_6: 21.years .. 64.years' }
        return []
      end

      # > Continuous Enrollment: Members must be continuously enrolled with a BH CP for at least 122 calendar days.
      unless continuously_enrolled_cp?(enrollments, measurement_year, min_days: 122)
        # trace_exclusion { "BH_CP_6: must be continuously enrolled with a BH CP for at least 122 calendar days" }
        return []
      end

      # > Exclusions: Enrollees in Hospice (Hospice Value Set)
      if claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
        trace_exclusion { "BH_CP_6: Exclude MemberRoster#id=#{member.id} is in hospice" }
        return []
      end

      # > Denominator: The sum of eligible days of members that are enrolled in a BH CP during the measurement year.
      # It is not clear from the spec but I believe this is the number of distinct cp_enrolled_dates (after they 122nd)
      # that are during the measurement year, and the measure is supposed to describe the fraction of those
      # that are spent in the 'community'. Gaps are not currently allowed so there
      # might be a faster way to do this rather than #to_a and the Array intersection operations below
      # but doing it this way allows for future gaps and is easier for check
      cp_enrolled_dates = enrollments.flat_map do |e|
        e.cp_enrolled_date_range.to_a.select { |d| measurement_year.cover?(d) }
      end.uniq.sort

      cp_enrolled_dates = cp_enrolled_dates[122..]
      return [] unless cp_enrolled_dates

      # > Numerator:
      # > Sum of eligible days in the community:
      # > Sum of eligible days within measurement period that a member is
      # > residing in the community without utilizing acute, chronic or
      # > post-acute (non-outpatient) institutional health care services from
      # > the date of BH CP assignment.

      # > Numerator = (Sum of eligible days from denominator specification
      # > above) – (sum of days in acute, chronic or post-acute institutional
      # > settings listed below).

      # > The table below contains both the MassHealth Provider Types and the
      # > corresponding Provider Types for ACO Models A and C that constitute an
      # > acute, chronic or post-acute (non-outpatient) institutional setting
      # > for this measure.
      # ....
      servicing_provider_types = ['70', '71', '73', '74', '76', '28', '35', '53', '09']

      billing_provider_types = ['1', '8', '40', '301', '3', '25', '246', '248', '20', '21', '35', '317', '22', '332', '34', '30', '31']

      # This is a mystery:
      # This one NPI is in the spec (in many places) by not in any data we have seen. Looking it up at
      # https://npiregistry.cms.hhs.gov/ responds with an error:
      #
      # > Error: Number - CMS deactivated NPI 1346326881. The provider can no longer use this NPI.
      # > Our public registry does not display provider information about NPIs that are not in service.
      #
      # Some random Excel document found online indicates it was deactivated on 11/22/2016 (pre the start of the CP program)
      # and the name of the entity found in the spec can only be found in very old data
      # harvesting sites like yellowpages.com
      special_npi = '1346326881'

      relavent_claims = claims.select do |c|
        (
          measurement_year.cover?(c.service_start_date) &&
          (
            c.servicing_provider_type.in?(servicing_provider_types) ||
            c.billing_provider_type.in?(billing_provider_types) ||
            (c.claim_type == 'inpatient' && (c.service_provider_npi == special_npi || c.pac.billing_npi == special_npi))
          )
        )
      end

      days_using_services = Set.new
      relavent_claims.each do |c|
        days_using_services += (c.service_start_date .. (c.service_end_date || c.service_start_date)).to_a
      end

      cp_enrolled_days = cp_enrolled_dates.size
      community_days = (cp_enrolled_dates - days_using_services.to_a).size

      # logger.debug "BH_CP_6: Found #{community_days}/#{cp_enrolled_days} days"
      [
        MeasureRow.new(
          row_type: 'enrolled days',
          row_id: member.id,
          bh_cp_6: [community_days, cp_enrolled_days],
        ),
      ]
    end

    private def calculate_bh_cp_7(member, claims, _enrollments)
      raise 'Not yet implemented'
      # # > TODO Age: Members who receive care from a Behavioral Health (BH) Community Partner (CP),
      # # > 21 to 64 years of age as of December 31 of the measurement year.
      # unless in_age_range?(member.date_of_birth, 21.years .. 64.years, as_of: dec_31_of_measurement_year)
      #   trace_exclusion { 'BH_CP_6: 21.years .. 64.years' }
      #   return []
      # end

      # # > TODO Continuous Enrollment: Members must be continuously enrolled with a BH CP for at least 122 calendar days.
      # unless continuously_enrolled_cp?(enrollments, measurement_year, min_days: 122)
      #   # trace_exclusion { "BH_CP_6: must be continuously enrolled with a BH CP for at least 122 calendar days" }
      #   return []
      # end

      # # > TODO Exclusions: Enrollees in Hospice (Hospice Value Set)
      # if claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
      #   trace_exclusion { "BH_CP_6: Exclude MemberRoster#id=#{member.id} is in hospice" }
      #   return []
      # end

      rows = [] # rubocop:disable Lint/UnreachableCode

      # puts "BH_CP_7:  MemberRoster#id=#{member.id}"
      claims.each do |claim|
        next unless aod_abuse_or_dependence?(claim)

        puts "AOD case found #{claim}"
        rows = MeasureRow.new(
          row_type: 'enrolled days',
          row_id: member.id,
          bh_cp_7: true,
        )
      end

      rows
    end

    # https://www.mass.gov/doc/change-of-address-provider-requirements-by-provider-type-3/download
    # Individual Provider Types:
    # PT-01 PHYSICIAN
    # PT-02 OPTOMETRIST
    # PT-03 OPTICIAN
    # PT-04 OCULARIST
    # PT-05 PSYCHOLOGIST
    # PT-06 PODIATRIST
    # PT-08 NURSE MIDWIFE
    # PT-16 CHIROPRACTOR
    # PT-17 NURSE PRACTITIONER
    # PT-39 PHYSICIAN ASSISTANT
    # PT-44 HEARING INSTRUMENT SPECIALIST
    # PT-50 AUDIOLOGIST
    # PT-51 CERTIFIED REGISTERED NURSE ANESTHETISTS
    # PT-57 CLINICAL NURSE SPECIALIST (CNS)
    # PT-78 PSYCHIATRIC CLINICAL NURSE SPECIALISTS (PCNS)
    # PT-86 QMB ONLY PROVIDERS (individuals)
    # PT-90 PHARMACIST
    # PT-92 CLINICAL SOCIAL WORKER
    # Entity Provider Types:
    # PT-36 DPH TRANSPORTATION (& DPH WAIVER)
    # PT-49 TRANSPORTATION
    # PT-95 COMPLEX CARE MANAGEMENT
    # PT-99 RELATIONSHIP ENTITY
    # PT-A5 CP CSA
    # PT-A6 CP LTSS
    # PT-A7 CP BH
    # PT-A8 ELTSS CP
    # PT-89 SCHOOL-BASED MEDICAID
    # PT-97 GROUP PRACTICE ORGANIZATION
    # PT-20 COMMUNITY HEALTH CENTER (CHC)
    # PT-21 FAMILY PLANNING AGENCY
    # PT-22 ABORTION/STERILIZATION CLINIC
    # PT-25 RENAL DIALYSIS CLINIC
    # PT-26 MENTAL HEALTH CENTER
    # PT-28 SUBSTANCE ABUSE PROGRAM
    # PT-29 EARLY INTERVENTION
    # PT-31 VOLUME PURCHASER
    # PT-33 CASE MANAGEMENT
    # PT-35 STATE AGENCY SERVICES
    # PT-40 PHARMACY
    # PT-45 INDEPENDENT DIAGNOSTIC TESTING FACILITY (IDTF)
    # PT-46 CERTIFIED INDEPENDENT LABORATORY
    # PT-53 ICF-MR STATE SCHOOL
    # PT-55 REST HOME
    # PT-65 PSYCHIATRIC DAY TREATMENT
    # PT-70 ACUTE INPATIENT HOSPITAL
    # PT-73 PSYCHIATRIC INPATIENT HOSPITAL (ALL AGES)
    # PT-74 SUBSTANCE ADDICTION DISORDER INPATIENT HOSPITAL
    # PT-75 SUBSTANCE ADDICTION DISORDER OUTPATIENT HOSPITAL
    # PT-76 INTENSIVE RESIDENTIAL TREATMENT PROGRAM (IRTP)
    # PT-80 ACUTE OUTPATIENT HOSPITAL
    # PT-81 HOSPITAL LICENSED HEALTH CENTER (HLHC)
    # PT-83 PSYCHIATRIC OUTPATIENT HOSPITAL
    # PT-84 AMBULATORY SURGERY CENTER
    # PT-86 QMB ONLY PROVIDERS (entities, organizations)
    # PT-87 RADIATION ONCOLOGY TREATMENT CENTERS
    # PT-91 INDIAN HEALTH SERVICES
    # PT-97 GROUP PRACTICE ORGANIZATION (group of therapists and dentists)
    # PT-96 LIMITED SERVICES CLINICS
    # PT-98 SPECIAL PROGRAMS: Flu Vaccine - LPHP Vaccine
    # PT-98 SPECIAL PROGRAMS: Certified Mastectomy Fitters (CMF)
    # PT-98 SPECIAL PROGRAMS: WIGS
    # PT-68 HOME CARE CORPORATION No
    # PT-98 SPECIAL PROGRAMS: ABI/MFP Waivers

    def assigned_enrollees
      assigned_enrollements_scope.distinct.count(:member_id)
    end
    memoize :assigned_enrollees

    def medical_claims
      medical_claims_scope.count
    end
    memoize :medical_claims

    private def percentage(enumerable, flag)
      denominator = 0
      numerator = 0
      enumerable.each do |r|
        value = r.send(flag)
        next if value.nil? # not part of this measure

        if value.is_a?(Array)
          numerator += value.first
          denominator += value.second
        else
          numerator += 1 if value
          denominator += 1
        end
      end

      return nil if denominator.zero?

      [numerator, denominator]
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

    def bh_cp_12
      percentage medical_claim_based_rows, :bh_cp_12
    end

    def bh_cp_13
      percentage medical_claim_based_rows, :bh_cp_13
    end

    # Map the names used in the various CMS Quality Rating System spec
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
      'Other Drug Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1426',
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
  end
end
