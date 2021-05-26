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

    def assigned_enrollements_scope
      scope = ::ClaimsReporting::MemberEnrollmentRoster

      # hud client properties
      scope = scope.joins(:patient).merge(::Health::Patient.where(client_id: hud_clients_scope.ids)) if filtered_by_client?

      # and via patient referral data
      scope = scope.joins(patient: :patient_referral).merge(::Health::PatientReferral.at_acos(filter.acos)) if filter.acos.present?

      # age
      scope = filter_for_age(scope, as_of: date_range.min)

      e_t = scope.quoted_table_name

      scope = scope.where(
        ["#{e_t}.cp_enroll_dt <= :max and (#{e_t}.cp_disenroll_dt IS NULL OR #{e_t}.cp_disenroll_dt > :max)", {
          min: cp_enollment_date_range.min,
          max: cp_enollment_date_range.max,
        }],
      )
      scope.where(
        member_id: ::ClaimsReporting::MemberRoster.where(date_of_birth: dob_range_1).select(:member_id),
      )
      scope
    end
    memoize :assigned_enrollements_scope

    def cp_enollment_date_range
      # Handle "September"
      # Members assigned to a BH CP on or between September 2nd of the year prior to the
      # measurement year and September 1st of the measurement year.
      #
      # The usually measurement year is Jan 1 - Dec 31 so we shift back by three named months and add a day
      (date_range.min << 4) + 1.day .. (date_range.max << 4) + 1.day
    end
    memoize :cp_enollment_date_range

    # Handle "September"
    # BH CP enrollees 18 years of age or older as of September 2nd of the year prior to
    # the measurement year and 64 years of age as of December 31st of the measurement year.
    def dob_range_1
      (dec_31_of_measurement_year - 64.years) .. (cp_enollment_date_range.min - 18.years)
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

    def rx_claims_scope
      ClaimsReporting::RxClaim.joins(
        :member_roster,
      ).where(
        member_id: assigned_enrollements_scope.select(:member_id),
      ).service_in(measurement_and_prior_year) # some measures care about scripts outside of the year
    end

    def measurement_and_prior_year
      (measurement_year.min - 1.year) .. measurement_year.max
    end

    def medical_claim_based_rows
      members_by_member_id = ::ClaimsReporting::MemberRoster.where(
        member_id: assigned_enrollements_scope.select(:member_id),
      ).select(
        :id,
        :member_id,
        :date_of_birth,
        :sex,
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

      logger.debug { "#{assigned_enrollements_scope.size} enrollment spans" }

      rows = []

      # only some measures need rx_claim data
      rx_claims_by_member_id = if measures.include?(:bh_cp_10)
        rx_claims_scope.select(
          :id,
          :member_id,
          #:member_dob,
          #:claim_number, # "billed on the same claim"
          #:cp_pidsl, # "same CP"
          :service_start_date,
          :ndc_code,
        ).group_by(&:member_id)
      else
        {}
      end

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
        :patient_status,
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
        :surgical_procedure_code_5
        #        :enrolled_days
      ).group_by(&:member_id)

      progress_proc = if Rails.env.development?
        require 'progress_bar'
        pb = ProgressBar.new(medical_claims_by_member_id.size, :counter, :bar, :percentage, :rate, :eta)
        ->(_item, _i, _result) { pb.increment! }
      end

      logger.debug { "#{medical_claims_scope.count} medical_claims" }

      value_set_lookups # preload before we potentially fork to save IO/ram

      rows = Parallel.flat_map(
        medical_claims_by_member_id,
        # we can spread the work below across many CPUS by removing/upping this number.
        # There is very little I/O so using in_threads wont help much till Ruby 3 Ractor (or other GIL workarounds)
        in_processes: 1,
        finish: progress_proc,
      ) do |member_id, claims|
        # we ideally do zero database calls in here

        rows = []
        member = members_by_member_id[member_id]

        if measures.include?(:bh_cp_1) || measures.include?(:bh_cp_2)
          date_of_birth = member.date_of_birth
          enrollments = enrollments_by_member_id.fetch(member_id)

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
        end

        rows.concat calculate_bh_cp_3(member, claims, enrollments) if measures.include?(:bh_cp_3)
        rows.concat calculate_bh_cp_4(member, claims, enrollments) if measures.include?(:bh_cp_4)
        rows.concat calculate_bh_cp_5(member, claims, enrollments) if measures.include?(:bh_cp_5)
        rows.concat calculate_bh_cp_6(member, claims, enrollments) if measures.include?(:bh_cp_6)

        # We don't have data to support these yet
        # rows.concat calculate_bh_cp_7(member, claims, enrollments) if measures.include?(:bh_cp_7)
        # rows.concat calculate_bh_cp_8(member, claims, enrollments) if measures.include?(:bh_cp_8)

        rows.concat calculate_bh_cp_9(member, claims, enrollments) if measures.include?(:bh_cp_9)

        if measures.include?(:bh_cp_10)
          rx_claims = rx_claims_by_member_id[member_id] || []
          rows.concat calculate_bh_cp_10(member, claims, rx_claims, enrollments)
        end

        enrollments = enrollments_by_member_id.fetch(member_id)
        rows.concat calculate_bh_cp_13(member, claims, enrollments) if measures.include?(:bh_cp_13)
        rows
      end
    end
    memoize :medical_claim_based_rows

    # Do the enrollments indicate continuous enrollment in a Community Partner
    private def continuously_enrolled_cp?(enrollments, date_range, min_days: nil)
      return false unless enrollments.present?

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
      return false unless enrollments

      selected_enrollments = enrollments.select { |e| e.span_date_range.overlaps?(date_range) }.sort

      selected_enrollments.each_cons(2) do |e_prev, e|
        if (e.span_start_date - e_prev.span_end_date) > max_gap
          # logger.debug { "Found enrollment gap > #{max_gap} #{e_prev.span_end_date.inspect}..#{e.span_start_date.inspect}" }
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
      enrollments && enrollments.any? { |e| e.cp_stop_rsn == 'Declined' }
    end

    private def measurement_year
      # FIXME: this is an abstraction, in an attempt to support
      # arbitrary date ranges. It is probably not reasonable to try.
      # Several places mention "September" or "December" of the [prior] measurement_year
      # so we need to deal with that offset. also the there is a lookup table for 2018,2019 years
      # that uses different offsets, half years etc
      date_range.max.beginning_of_year .. date_range.max.end_of_year
    end

    private def dec_31_of_measurement_year
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

    def missing_value_sets
      @missing_value_sets ||= Set.new
    end

    private def in_set?(vs_name, claim, dx1_only: false)
      codes_by_system = value_set_lookups.fetch(vs_name) do
        # TODO? raise/warn on an unrecognised code_system_name?
        missing_value_sets << vs_name
        # logger.error { "MISSING #{vs_name}" }
        {}
      end

      # TODO?: Can we use LOINC (labs) or CVX (vaccine) codes
      # What about "Modifier"

      # MY 2020 HEDIS for QRS Version—NCQA Page - 2021 QRS Measure TechSpecs_20200925_508.pdf  Sec 37 Code Modifiers
      # > Modifiers are two extensions that, when added to CPT or HCPCS codes,
      # > provide additional information about a service or procedure. Exclude
      # > any CPT Category II code in conjunction with a 1P, 2P, 3P or 8P
      # > modifier code (CPT CAT II Modifier Value Set) from HEDIS for QRS
      # > reporting.  These modifiers indicate the service did not occur. In
      # > the HEDIS for QRS Value Set Directory, CPT Category II codes are
      # > identified in the Code System column as “CPT-CAT-II.” Unless
      # > otherwise specified, if a CPT or HCPCS code specified in HEDIS for
      # > QRS appears in the organization’s database with any modifier other
      # > than those specified above, the code may be counted in the HEDIS for
      # > QRS measure.

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
        return trace_set_match!(vs_name, claim, :ICD10CM) if claim.matches_icd10cm?(code_pattern, dx1_only)
      end
      if (code_pattern = codes_by_system['ICD10PCS'])
        return trace_set_match!(vs_name, claim, :ICD10PCS) if claim.matches_icd10pcs? code_pattern
      end

      # Slow and rare
      if (code_pattern = codes_by_system['ICD9CM'])
        return trace_set_match!(vs_name, claim, :ICD9CM) if claim.matches_icd9cm?(code_pattern, dx1_only)
      end

      if (code_pattern = codes_by_system['ICD9PCS']) # rubocop:disable Style/GuardClause
        return trace_set_match!(vs_name, claim, :ICD9PCS) if claim.matches_icd9pcs? code_pattern
      end
    end

    private def rx_in_set?(vs_name, claim)
      codes_by_system = value_set_lookups.fetch(vs_name)

      # TODO? RxNorm, CVX might also show up lookup code but we dont have any claims data with that info, nor a crosswalk handy
      # TODO? raise/warn on an unrecognised code_system_name?

      if (ndc_codes = codes_by_system['NDC']).present? # rubocop:disable Style/GuardClause
        return trace_set_match!(vs_name, claim, :NDC) if ndc_codes.include?(claim.ndc_code)
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
          # We need to process these lookup tables to work well wth the claims reporting data
          if code_system.in? ['ICD10CM', 'ICD10PCS', 'ICD9CM', 'ICD10PCS']
            # we don't generally have decimals in data and should match on prefixes
            codes = codes.map { |code| code.gsub('.', '') }
            lookup_table[vs_name][code_system] = Regexp.new "^(#{codes.join('|')})"
          elsif code_system.in? ['UBTOB', 'UBREV']
            # our claims data doesn't have leading zeros
            codes = codes.flat_map { |code| code.gsub(/^0/, '') }
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

    # hook to log exclusions
    private def trace_exclusion(&block)
      # logger.debug(&block)
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
        followup_dates = c.followup_period(7).to_a
        assert "followup_dates must be 8 days, was #{followup_dates.size} days.", followup_dates.size == 8

        unless continuously_enrolled_cp?(enrollments, followup_dates)
          trace_exclusion { "BH_CP_4: Exclude claim #{c.id}: not continuously_enrolled_in_cp during #{followup_dates.min .. followup_dates.max}" }
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
        followup_period = c.followup_period(7).to_a

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

    private def acute_inpatient_stay?(claim)
      inpatient_stay?(claim) && !in_set?('Nonacute Inpatient Stay', claim)
    end

    private def mental_health_hospitalization?(claim)
      (
        in_set?('Mental Illness', claim, dx1_only: true) || in_set?('Intentional Self-Harm', claim, dx1_only: true)
      ) && acute_inpatient_stay?(claim)
    end

    # Follow-Up After Hospitalization for Mental Illness (7 days)
    private def calculate_bh_cp_9(member, claims, enrollments)
      rows = []

      # > Exclusions: Enrollees in Hospice (Hospice Value Set)
      if claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
        trace_exclusion do
          "BH_CP_9: Exclude MemberRoster#id=#{member.id} is in hospice"
        end
        return rows
      end

      # > Also Exclude: Members who decline to engage with the BH CP.
      return rows if declined_to_engage?(enrollments)

      mh_discharges = []
      claims.each do |c|
        # > The denominator for this measure is based on discharges, not on enrollees.
        # > If enrollees have more than one discharge, include all discharges on or
        # > between January 1 and December 1 of the measurement year.

        # Since there is logic about checking for readmissions up to 7 days after
        # we need to find those too
        year_plus_followup = measurement_year.min .. 7.days.after(measurement_year.max)
        next unless c.discharge_date && year_plus_followup.cover?(c.service_start_date) && mental_health_hospitalization?(c)

        assert 'Mental health hospitalization visit must have a discharge_date', c.discharge_date.present?

        # > BH CP enrollees 18 to 64 years of age as of the date of discharge."
        unless in_age_range?(c.member_dob, 18.years .. 64.years, as_of: c.discharge_date)
          # trace_exclusion { "BH_CP_9: Exclude claim #{c.id}: DOB: #{c.member_dob} outside age range as of #{c.discharge_date}" }
          next
        end

        # > Continuously enrolled with BH CP from date of discharge through 7
        # > calendar days after discharge. There is no requirement for MassHealth enrollment."
        followup_dates = c.followup_period(7).to_a
        assert "followup_dates must be 8 days, was #{followup_dates.size} days.", followup_dates.size == 8

        # > No allowable gap in BH CP enrollment during the continuous enrollment period.
        unless continuously_enrolled_cp?(enrollments, followup_dates)
          # trace_exclusion { "BH_CP_9: Exclude claim #{c.id}: not continuously_enrolled_in_cp during #{followup_dates.min .. followup_dates.max}" }
          next
        end

        mh_discharges << c
      end

      # **Note**: The exclusion logic below is done as close to the English spec as possible
      # to make it possible to connect the two.  It feels like it could be further optomized
      # since the readmit/transfer to (*) logic seems to be redundant

      # > If the readmission/direct transfer to the acute inpatient care setting was for a
      # > principal diagnosis of mental health disorder or intentional self-harm
      # > (Mental Health Diagnosis Value count only the last discharge.
      #
      # i.e. remove all but the last mental_health_hospitalization if
      # re-admitted/transfered within the 7 day follow-up period
      mh_final_discharges = []
      mh_discharges.each_with_index do |d, idx|
        d_next = d[idx + 1]

        next if d_next && d.followup_period(7).cover?(d_next.admit_date)

        mh_final_discharges << d
      end

      # > Exclude both the initial discharge and the readmission/direct transfer discharge
      # > if the last discharge occurs after December 1 of the measurement year.
      mh_final_discharges.reject! { |d| d.discharge_date > measurement_year.max }

      unless mh_final_discharges.empty?
        # puts "MemberRoster#id=#{member.id}: mh_final_discharges: #{mh_discharges.map(&:stay_date_range).join(' ')}"
      end

      # collect the dates we might need to search for a readmit or cp followup
      # this is to avoid a researching (all claims x all mh_final_discharges)
      followup_days = Set.new
      mh_final_discharges.each do |c|
        followup_days |= c.followup_period(7).to_a
      end

      # > Identify readmissions and direct transfers to an acute inpatient
      # > care setting during the 7-day follow-up period:
      # >  1. Identify all acute and nonacute inpatient stays (Inpatient Stay Value Set).
      # >   2. Exclude nonacute inpatient stays (Nonacute Inpatient Stay Value Set).
      # >   3. Identify the admission date for the stay.

      # Narrow down the claims we need to compare to discharges to
      # those of the right type and in the universe of followup_days
      readmits = []
      eligable_cp_followups = []
      claims.each do |c|
        # readmits for other than mh health (we will later classify acute/non-acute)
        readmits << c if c.admit_date && followup_days.include?(c.admit_date) && !c.in?(mh_discharges)

        # cp followups we might use later
        eligable_cp_followups << c if cp_followup?(c) && followup_days.include?(c.service_start_date)
      end

      # puts "MemberRoster#id=#{member.id}: non-mental_health_hospitalization readmits: #{readmits.map(&:stay_date_range).join(' ')}" unless readmits.empty?
      # puts "MemberRoster#id=#{member.id}: eligable_cp_followups: #{eligable_cp_followups.map(&:stay_date_range).join(' ')}" unless eligable_cp_followups.empty?

      # > If the readmission/direct transfer to the acute inpatient care setting was for
      # > any other principal diagnosis exclude both the original and the readmission/direct
      # > transfer discharge.
      # FIXME
      # mh_final_discharges.reject! do |d|
      # ...
      # end

      # > Exclude discharges followed by readmission or direct transfer to a nonacute
      # > inpatient care setting within the 7-day follow-up period, regardless of
      # > principal diagnosis for the readmission. To identify readmissions and direct
      # > transfers to a nonacute inpatient care setting:
      # >   1. Identify all acute and nonacute inpatient stays (Inpatient Stay Value Set).
      # >   2. Confirm the stay was for nonacute care based on the presence of a nonacute code (Nonacute Inpatient Stay Value Set) on the claim.
      # >   3. Identify the admission date for the stay.
      # > These discharges are excluded from the measure because rehospitalization or
      # > direct transfer may prevent an outpatient follow-up visit from taking place.
      mh_final_discharges.reject! do |d|
        readmits.any? { |readmit| d.followup_period(7).cover?(readmit) && acute_inpatient_stay?(readmit) }
      end

      mh_final_discharges.each do |c|
        followup_period = c.followup_period(7)
        eligable_followup = eligable_cp_followups.any? { |f| followup_period.cover?(f.service_start_date) }
        row = MeasureRow.new(
          row_type: 'visit',
          row_id: c.id,
          bh_cp_9: eligable_followup,
        )
        # puts "Found #{row.inspect}" if row.bh_cp_9
        rows << row
      end
      rows
    end

    private def schizophrenia_or_bipolar_disorder?(claims)
      # ... Schizophrenia Value Set; Bipolar Disorder Value Set; Other Bipolar Disorder Value Set
      claims_with_dx = claims.select do |c|
        in_set?('Schizophrenia', c) || in_set?('Bipolar Disorder', c) || in_set?('Other Bipolar Disorder', c)
      end
      return false if claims_with_dx.none?

      # > At least one acute inpatient encounter, with any diagnosis of schizophrenia, schizoaffective disorder or bipolar disorder.
      # - BH Stand Alone Acute Inpatient Value Set with...
      # - Visit Setting Unspecified Value Set with Acute Inpatient POS Value Set...
      if claims_with_dx.any? { |c| in_set?('BH Stand Alone Acute Inpatient', c) || (in_set?('Visit Setting Unspecified', c) && in_set?('Acute Inpatient POS', c)) }
        puts 'BH_CP_10: At least one inpatient....'
        return true
      end

      # > At least two of the following, on different dates of service, with or without a telehealth modifier (Telehealth Modifier Value Set)
      visits = claims_with_dx.select do |c|
        in_set?('Visit Setting Unspecified', c) && (
          in_set?('Acute Inpatient POS', c) ||
          in_set?('Community Mental Health Center POS', c) ||
          in_set?('ED POS', c) ||
          in_set?('Nonacute Inpatient POS', c) ||
          in_set?('Partial Hospitalization', c) ||
          in_set?('Telehealth POS', c)
        ) ||
        in_set?('BH Outpatient', c) ||
        in_set?('BH Stand Alone Nonacute Inpatient', c) ||
        in_set?('ED', c) ||
        in_set?('Electroconvulsive Therapy', c) ||
        in_set?('Observation', c) ||
        in_set?('Partial Hospitalization/Intensive Outpatient', c)
      end

      # > where both encounters have any diagnosis of schizophrenia or schizoaffective disorder (Schizophrenia Value Set)
      if visits.select { |c| in_set?('Schizophrenia', c) }.uniq(&:service_start_date).size >= 2
        puts 'BH_CP_10: At least two Schizophrenia....'
        return true
      end

      # > or both encounters have any diagnosis of bipolar disorder (Bipolar Disorder Value Set; Other Bipolar Disorder Value Set).
      if visits.select { |c| in_set?('Bipolar Disorder', c) || in_set?('Other Bipolar Disorder', c) }.uniq(&:service_start_date).size >= 2
        puts 'BH_CP_10: At least two Bipolar....'
        return true
      end

      return false
    end

    private def diabetes?(_claims, rx_claims)
      # There are two ways to identify members with
      # diabetes: by claim/encounter data and by pharmacy data.  The
      # organization must use both methods to identify enrollees with
      # diabetes, but an enrollee need only be identified by one method to be
      # excluded from the measure. Enrollees may be identified as having
      # diabetes during the measurement year or the year prior to the
      # measurement year.

      # TODO – Claim/encounter data. Enrollees who met at any of the following
      # criteria during the measurement year or the year prior to the
      # measurement year (count services that occur over both years).

      #   - At least one acute inpatient encounter (Acute Inpatient Value Set)
      #   with a diagnosis of diabetes (Diabetes Value Set) without (Telehealth
      #   Modifier Value Set; Telehealth POS Value Set).

      #   - At least two outpatient visits (Outpatient Value Set), observation
      #   visits (Observation Value Set), ED visits (ED Value Set) or nonacute
      #   inpatient encounters (Nonacute Inpatient Value Set) on different dates
      #   of service, with a diagnosis of diabetes (Diabetes Value Set). Visit
      #   type need not be the same for the two encounters.

      #   Only include nonacute inpatient encounters (Nonacute Inpatient Value
      #   Set) without telehealth (Telehealth Modifier Value Set; Telehealth POS
      #   Value Set).

      #   Only one of the two visits may be a telehealth visit, a telephone
      #   visit or an online assessment. Identify telehealth visits by the
      #   presence of a telehealth modifier (Telehealth Modifier Value Set) or
      #   the presence of a telehealth POS code (Telehealth POS Value Set)
      #   associated with the outpatient visit. Use the code combinations below
      #   to identify telephone visits and online assessments:

      #   – A telephone visit (Telephone Visits Value Set) with any diagnosis of
      #   diabetes (Diabetes Value Set).

      #   – An online assessment (Online Assessments Value Set) with any diagnosis
      #   of diabetes (Diabetes Value Set).

      # – Pharmacy data. Enrollees who were dispensed insulin or oral
      #   hypoglycemics/antihyperglycemics during the measurement year or
      #   year prior to the measurement year on an ambulatory basis (Diabetes Medications List).
      #   TODO: on an ambulatory basis????
      #   Cant find docs on calculating this but I'm betting we can do something by looking for
      #   overlapping inpatient stays
      diabetes_rx = rx_claims.detect do |c|
        measurement_and_prior_year.cover?(c.service_start_date) && rx_in_set?('Diabetes Medications', c)
      end
      if diabetes_rx # rubocop:disable Style/GuardClause
        trace_exclusion do
          "BH_CP_10: Excludes MemberRoster#id=#{member.id} Enrollees with diabetes due to diabetes_rx RxClaim#id=#{diabetes_rx.inspect}"
        end
        return true
      end
    end

    private def antipsychotic_meds?(_claims, rx_claims)
      # There are two ways to identify dispensing events: by
      # claim/encounter data and by pharmacy data. The organization must use
      # both methods to identify dispensing events, but an event need only be
      # identified by one method to be counted.

      # – Pharmacy data. Dispensed an antipsychotic medication (SSD
      # – Antipsychotic Medications List) on an ambulatory basis.

      # Note: Also including Long Acting Injections which are the med lists matching
      # our missing Long-Acting Injections Value Set
      return true if rx_claims.detect do |c|
        measurement_and_prior_year.cover?(c.service_start_date) && (
          rx_in_set?('SSD Antipsychotic Medications', c) ||
          rx_in_set?('Long Acting Injections 14 Days Supply Medications', c) ||
          rx_in_set?('Long Acting Injections 30 Days Supply Medications', c) ||
          rx_in_set?('Long Acting Injections 28 Days Supply Medications', c)
        )
      end

      # – Claim/encounter data. An antipsychotic medication (Long-Acting
      # – Injections Value Set).
      # TODO. We need the missing Long-Acting Injections Value Set
    end

    # Diabetes Screening for Individuals With Schizophrenia or Bipolar Disorder Who Are Using Antipsychotic Medications
    private def calculate_bh_cp_10(member, claims, rx_claims, _enrollments)
      rows = []

      # > BH CP enrollees 18 to 64 years of age as of December 31 of the measurement year.
      unless in_age_range?(member.date_of_birth, 18.years .. 64.years, as_of: dec_31_of_measurement_year)
        trace_exclusion do
          "BH_CP_10: Exclude MemberRoster#id=#{member.id} based on age #{member.date_of_birth}"
        end
        return []
      end

      measurement_year_claims = claims.select { |c| measurement_year.cover?(c.service_start_date) }

      # > Exclusions: Enrollees in Hospice (Hospice Value Set)
      if measurement_year_claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
        trace_exclusion do
          "BH_CP_10: Exclude MemberRoster#id=#{member.id} is in hospice"
        end
        return []
      end

      # Step 1: Identify enrollees with schizophrenia or bipolar disorder as those who met at least one of the following criteria during the measurement year
      return [] unless schizophrenia_or_bipolar_disorder?(measurement_year_claims)

      puts "BH_CP_10: MemberRoster#id=#{member.id} -- Found schizophrenia or bipolar disorder"

      # Exclude enrollees who met any of the following criteria:
      # Enrollees with diabetes.
      if diabetes?(claims, rx_claims)
        puts "BH_CP_10: MemberRoster#id=#{member.id} -- Excluded due to diabetes"
        return []
      end
      # NOT taking antipsychotics
      unless antipsychotic_meds?(claims, rx_claims)
        puts "BH_CP_10: MemberRoster#id=#{member.id} -- Excluded due to not taking antipsychotis meds"
        return []
      end

      # > Enrollment
      #
      # The spec is a bit confusing here... basically we need to test potentially
      # several periods of enrollment. If there are **no** CP disenrollments we
      # check the full measurement year. If there are some we look at the one year period
      # before each disenrollment.
      # In both case we exclude cases if less than 122 days CP enrollment or
      # with MH enrollment gaps of over 45 days
      cp_disenrollments = enrollments.select do |e|
        e.cp_disenroll_dt.present? && measurement_year.cover?(e.cp_disenroll_dt)
      end
      covered_ranges = if cp_disenrollments.none?
        # For members continuously enrolled with the CP for at least 122 days,
        # and with no CP disenrollment during the measurement year....
        [measurement_year]
      else
        # > BH CP enrollees with a CP disenrollment during the measurement year
        # > must be continuously enrolled in MassHealth for one year prior to the
        # > disenrollment date.
        cp_disenrollments.map do |e|
          (e.cp_disenroll_dt - 1.year) .. e.cp_disenroll_dt
        end
      end
      covered_ranges.each do |required_range|
        unless continuously_enrolled_cp?(enrollments, required_range, min_days: 122)
          trace_exclusion { "BH_CP_10: MemberRoster#id=#{member.id}  must be continuously enrolled with a BH CP for at least 122 calendar days. required_mh_range: #{required_mh_range}" }
          return []
        end
        unless continuously_enrolled_mh?(enrollments, required_range, max_gap: 45)
          trace_exclusion { "BH_CP_10: MemberRoster#id=#{member.id} must be continuously enrolled in MassHealth. required_mh_range: #{required_mh_range}" }
          return []
        end

        diabetes_screening = claims.detect do |c|
          required_range.cover?(c) && (in_set?('Glucose Tests', c) || in_set?('HbA1c Tests', c))
        end
        if diabetes_screening # rubocop:disable Style/IfUnlessModifier
          puts "BH_CP_10: MemberRoster#id=#{member.id} -- Found diabetes_screening=#{diabetes_screening.inspect}"
        end
        row = MeasureRow.new(
          row_type: 'enrollee',
          row_id: "#{member.id}-#{required_range.min}-#{required_range.max}",
          bh_cp_10: diabetes_screening.present?,
        )
        rows << row
      end

      rx_claims.each do |c|
        puts "BH_CP_10: Diabetes Medication found in #{c.inspect}" if rx_in_set?('Diabetes Medications', c)
        puts "BH_CP_10: SSD Antipsychotic Medications found in #{c.inspect}" if rx_in_set?('SSD Antipsychotic Medications', c)
      end

      rows
    end

    # BH CP #13: Hospital Readmissions (Adult)
    private def calculate_bh_cp_13(member, claims, enrollments)
      rows = []

      # puts "BH_CP_13: Checking MemberRoster#id=#{member.id}"
      # > Exclusions: Enrollees in Hospice (Hospice Value Set)
      if claims.any? { |c| measurement_year.cover?(c.service_start_date) && hospice?(c) }
        trace_exclusion do
          "BH_CP_13: Exclude MemberRoster#id=#{member.id} is in hospice"
        end
        return []
      end

      # > Exclude: Members who decline to engage with the BH CP.
      return [] if declined_to_engage?(enrollments)

      #  between January 3 and December 31 of the measurement year
      year = measurement_year.max.year
      readmit_range = Date.new(year, 1, 3) .. Date.new(year, 12, 31)

      # > Step 1: Identify all acute inpatient discharges on or between January 1 and December 1 of the measurement year
      # We select discharges for the whole year and filter later because we we need overlapping but different
      # Discharge ranges for both the Numerator and denominator
      acute_inpatient_claims = claims.select do |c|
        c.discharge_date.present? && measurement_year.cover?(c.discharge_date) && acute_inpatient_stay?(c)
      end.sort_by(&:admit_date)

      # > Step 2: Acute-to-acute direct transfers
      # > A direct transfer is when the discharge date from the first inpatient setting precedes
      # > the admission date to a second inpatient setting by one calendar day or less.

      # so we split this history into "stays" that include any direct transfers
      acute_inpatient_stays = acute_inpatient_claims.slice_when do |c1, c2|
        (c2.admit_date - c1.discharge_date) > 1
      end.to_a

      n_stays = acute_inpatient_stays.size
      raise 'Too many stays to compare' if n_stays > 10_000

      # puts "Checking #{n_stays}x#{n_stays}=#{n_stays**2} stay pairs" if n_stays > 0

      acute_inpatient_stays.each do |stay_claims|
        admit = stay_claims.first
        discharge = stay_claims.last
        index_admission_date = admit.admit_date
        index_discharge_date =  discharge.discharge_date

        if index_admission_date == index_discharge_date
          # > Step 3 Exclude hospital stays where the Index Admission Date is the same as the Index Discharge Date.
          trace_exclusion do
            "BH_CP_13: MedicalClaim#id=#{admit.id} Exclude hospital stays where the Index Admission Date is the same as the Index Discharge Date"
          end
          next
        end
        # > Step 4: Exclude hospital stays for the following reasons:
        # ...
        # > Note: For hospital stays where there was an acute-to-acute
        # > direct transfer (identified in step 2), use both the
        # > original stay and the direct transfer stay to identify
        # > exclusions in this step.
        next if stay_claims.any? do |c|
          exclude = false
          exclude ||= c.discharge_date > Date.new(year, 12, 1) # Step 1...
          exclude ||= if c.discharged_due_to_death? || c.dead_upon_arrival?
            trace_exclusion do
              "BH_CP_13: MedicalClaim#id=#{c.id} The enrollee died during the stay"
            end
            true
          end
          exclude ||= if member.sex == 'Female' && in_set?('Pregnancy', c, dx1_only: true)
            trace_exclusion do
              "BH_CP_13: MedicalClaim#id=#{c.id} Female enrollees with a principal diagnosis of pregnancy"
            end
            true
          end
          exclude ||= if in_set?('Perinatal Conditions', c, dx1_only: true)
            trace_exclusion do
              "BH_CP_13: MedicalClaim#id=#{c.id} A principal diagnosis of a condition originating in the perinatal period"
            end
            true
          end
          exclude
        end

        # >  Step 5 Calculate continuous enrollment.
        # > Members must be continuously enrolled in MassHealth 365
        # > days prior to the Index Discharge Date through 30 days after
        # > the Index Discharge Date;
        continuous_range = 365.days.before(index_discharge_date) .. 30.days.after(index_discharge_date)
        unless continuously_enrolled_mh?(enrollments, continuous_range, max_gap: 45)
          trace_exclusion do
            "BH_CP_13: MemberRoster#id=#{member.id} Not continuously_enrolled_mh for the year #{continuous_range}"
          end
          next
        end
        # > they must also be continuously
        # > enrolled with the BH CP from the Index Discharge Date
        # > through 30 days after the Index Discharge Date.
        unless continuously_enrolled_cp?(enrollments, index_discharge_date .. 30.days.after(index_discharge_date))
          trace_exclusion do
            "BH_CP_13: MemberRoster#id=#{member.id} Not continuously_enrolled_cp for 30 days after #{index_discharge_date}"
          end
          next
        end
        # > no gap in MassHealth enrollment or BH CP enrollment
        # > during the 30 days following the Index Discharge Date.
        unless continuously_enrolled_mh?(enrollments, index_discharge_date .. 30.days.after(index_discharge_date), max_gap: 0)
          trace_exclusion do
            "BH_CP_13: MemberRoster#id=#{member.id} Not continuously_enrolled_mh for 30 days after #{index_discharge_date}"
          end
          next
        end

        # > Numerator: At least one acute readmission for any diagnosis within 30 days of the Index Discharge Date.
        # FIXME? O(n^2) but n is tiny
        # We are using acute_inpatient_stays again to do:
        # > Steo 1: Identify all acute inpatient stays with an admission date on or between January 3 and December 31 of the measurement year.
        # > Step 2: Acute-to-acute direct transfers
        readmitted_in_30_days = n_stays > 1 && acute_inpatient_stays.any? do |other_stay|
          readmit_date = other_stay.first.admit_date

          next unless readmit_range.cover?(readmit_date) # Numerator Step 1

          next unless (readmit_date - index_discharge_date).between?(2, 30)

          # > Step 3: Exclude ... Pregnancy/perinatal
          next if stay_claims.any? do |c|
            exclude = false
            exclude ||= if member.sex == 'Female' && in_set?('Pregnancy', c, dx1_only: true)
              trace_exclusion do
                "BH_CP_13: MedicalClaim#id=#{c.id} Female enrollees with a principal diagnosis of pregnancy"
              end
              true
            end
            exclude ||= if in_set?('Perinatal Conditions', c, dx1_only: true)
              trace_exclusion do
                "BH_CP_13: MedicalClaim#id=#{c.id} A principal diagnosis of a condition originating in the perinatal period"
              end
              true
            end

            exclude
          end
          # > Step 3: Exclude ... Planned Admissions
          next if stay_claims.any? do |c|
            if in_set?('Chemotherapy', c, dx1_only: true) ||
              in_set?('Readmissions', c, dx1_only: true) ||
              in_set?('Kidney Transplant', c) ||
              in_set?('Bone Marrow Transplant', c) ||
              in_set?('Organ Transplant Other Than Kidney', c) ||
              in_set?('Introduction of Autologous Pancreatic Cells', c) ||
              (in_set?('Potentially Planned Procedures', c) && !in_set?('Acute Condition', c))
            then # rubocop:disable Style/MultilineIfThen
              # puts "BH_CP_13: MedicalClaim#id=#{c.id} Planned Admissions"
              true
            end
          end

          true
        end
        # puts "BH_CP_13: Found readmitted_in_30_days" if readmitted_in_30_days

        # puts 'BH_CP_13: Found an IHS'
        row = MeasureRow.new(
          row_type: 'stay',
          row_id: "#{admit.id}-#{discharge.id}",
          bh_cp_13: readmitted_in_30_days,
        )
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

    private def trace_set_match!(vs_name, claim, code_type) # rubocop:disable Lint/UnusedMethodArgument
      # puts "in_set? #{vs_name} matched #{code_type} for Claim#id=#{claim.id}"
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
      # all the claims in the same 'stay'
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
          "BH_CP_5: Exclude MemberRoster#id=#{member.id} based on age #{member.date_of_birth}"
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
        trace_exclusion { "BH_CP_6: Exclude MemberRoster#id=#{member.id} 21.years .. 64.years" }
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
        next if value.nil? # row does not included in this measure

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

    MEDICATION_LISTS = {
      'SSD Antipsychotic Medications' => '2.16.840.1.113883.3.464.1004.2173',
      'Diabetes Medications' => '2.16.840.1.113883.3.464.1004.2050',
      'Opioid Use Disorder Treatment Medications' => '2.16.840.1.113883.3.464.1004.2142',
      'Alcohol Use Disorder Treatment Medications' => '2.16.840.1.113883.3.464.1004.2026',
      # Note, the MH spec says there is a "Long-Active Injections" claims Value Set
      # which I was not able to find. These med lists seem like a good proxy for now
      'Long Acting Injections 14 Days Supply Medications' => '2.16.840.1.113883.3.464.1004.2100',
      'Long Acting Injections 30 Days Supply Medications' => '2.16.840.1.113883.3.464.1004.2190',
      'Long Acting Injections 28 Days Supply Medications' => '2.16.840.1.113883.3.464.1004.2101',
    }.freeze

    # Map the names used in the various CMS Quality Rating System spec
    # to the OIDs. Names will not be unique in Hl7::ValueSetCode as we load
    # other sources
    # MISSING for BH CP 10
    # - Schizophrenia
    # - Bipolar Disorder
    # - Other Bipolar Disorder
    # - BH Stand Alone Acute Inpatient
    # - BH Stand Alone Nonacute Inpatient
    # - Nonacute Inpatient POS
    # - Long-Acting Injections - see note near "Long Acting Injections" in MEDICATION_LISTS
    VALUE_SETS = MEDICATION_LISTS.merge({
      'Acute Condition' => '2.16.840.1.113883.3.464.1004.1324', # rubocop:disable Layout/FirstHashElementIndentation
      'Acute Inpatient' => '2.16.840.1.113883.3.464.1004.1017',
      'Alcohol Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1424',
      'Ambulatory Surgical Center POS' => '2.16.840.1.113883.3.464.1004.1480',
      'AOD Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1013',
      'AOD Medication Treatment' => '2.16.840.1.113883.3.464.1004.2017',
      'BH Outpatient' => '2.16.840.1.113883.3.464.1004.1481',
      'Bone Marrow Transplant' => '2.16.840.1.113883.3.464.1004.1325',
      'Chemotherapy' => '2.16.840.1.113883.3.464.1004.1326',
      'Community Mental Health Center POS' => '2.16.840.1.113883.3.464.1004.1484',
      'Detoxification' => '2.16.840.1.113883.3.464.1004.1076',
      'Diabetes' => '2.16.840.1.113883.3.464.1004.1077',
      'ED POS' => '2.16.840.1.113883.3.464.1004.1087',
      'ED' => '2.16.840.1.113883.3.464.1004.1086',
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
      'Introduction of Autologous Pancreatic Cells' => '2.16.840.1.113883.3.464.1004.1459',
      'Kidney Transplant' => '2.16.840.1.113883.3.464.1004.1141',
      'Mental Health Diagnosis' => '2.16.840.1.113883.3.464.1004.1178',
      'Mental Illness' => '2.16.840.1.113883.3.464.1004.1179',
      'Nonacute Inpatient Stay' => '2.16.840.1.113883.3.464.1004.1398',
      'Nonacute Inpatient' => '2.16.840.1.113883.3.464.1004.1189',
      'Observation' => '2.16.840.1.113883.3.464.1004.1191',
      'Online Assessments' => '2.16.840.1.113883.3.464.1004.1446',
      'Opioid Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1425',
      'Organ Transplant Other Than Kidney' => '2.16.840.1.113883.3.464.1004.1195',
      'Other Drug Abuse and Dependence' => '2.16.840.1.113883.3.464.1004.1426',
      'Outpatient POS' => '2.16.840.1.113883.3.464.1004.1443',
      'Outpatient' => '2.16.840.1.113883.3.464.1004.1202',
      'Partial Hospitalization POS' => '2.16.840.1.113883.3.464.1004.1491',
      'Partial Hospitalization/Intensive Outpatient' => '2.16.840.1.113883.3.464.1004.1492',
      'Perinatal Conditions' => '2.16.840.1.113883.3.464.1004.1209',
      'Potentially Planned Procedures' => '2.16.840.1.113883.3.464.1004.1327',
      'Pregnancy' => '2.16.840.1.113883.3.464.1004.1219',
      'Rehabilitation' => '2.16.840.1.113883.3.464.1004.1328',
      'Telehealth Modifier' => '2.16.840.1.113883.3.464.1004.1445',
      'Telehealth POS' => '2.16.840.1.113883.3.464.1004.1460',
      'Telephone Visits' => '2.16.840.1.113883.3.464.1004.1246',
      'Transitional Care Management Services' => '2.16.840.1.113883.3.464.1004.1462',
      'Visit Setting Unspecified' => '2.16.840.1.113883.3.464.1004.1493',
      'Well-Care' => '2.16.840.1.113883.3.464.1004.1262',
    }).freeze # rubocop:disable Layout/FirstHashElementIndentation

    # Table_CC_Comorbid
    #
    # rubocop:disable Layout/ArrayAlignment, Style/WordArray, Style/PercentLiteralDelimiters
    # Downloaded 2021-05-25
    HCC_SURG = %w/00210 00211 00216 00350 00404 00406 00500 00540 00541 00542 00546
      00548 00560 00561 00562 00563 00566 00567 00580 00600 00604 00620 00622 00625
      00626 00670 00792 00794 00796 00844 00846 00848 00860 00862 00864 00865 00866
      00868 00880 00904 00906 00908 00926 00928 00932 00934 00936 00944 01130 01140
      01150 01173 01210 01212 01214 01215 01230 01232 01234 01270 01272 01274 01360
      01392 01400 01402 01404 01480 01482 01484 01486 01500 01638 01654 01656 01760
      11450 11451 11462 11463 11470 11471 11771 11772 11960 11970 11971 13160 14000
      14001 14020 14021 14040 14041 14060 14061 14300 14301 14350 15050 15100 15110
      15115 15120 15130 15135 15150 15155 15170 15175 15200 15220 15240 15260 15300
      15320 15330 15335 15350 15360 15365 15400 15420 15430 15570 15572 15574 15576
      15580 15600 15610 15620 15625 15630 15650 15731 15732 15734 15736 15738 15740
      15750 15756 15757 15758 15760 15770 15780 15781 15782 15783 15788 15789 15792
      15793 15810 15811 15819 15820 15821 15822 15823 15830 15831 15832 15833 15834
      15835 15836 15837 15838 15839 15840 15841 15842 15845 15920 15922 15931 15933
      15934 15935 15936 15937 15940 15941 15944 15945 15946 15950 15951 15952 15953
      15956 15958 17106 17107 17108 19020 19110 19112 19120 19125 19140 19160 19162
      19180 19182 19200 19220 19240 19260 19271 19272 19300 19301 19302 19303 19304
      19305 19306 19307 19316 19318 19324 19325 19328 19330 19340 19342 19350 19355
      19357 19361 19364 19366 19367 19368 19369 19370 19371 19380 20150 20661 20662
      20663 20664 20680 20690 20692 20693 20694 20696 20802 20805 20808 20816 20822
      20824 20827 20838 20910 20912 20920 20922 20924 20926 20955 20956 20957 20962
      20969 20970 20972 20973 21010 21011 21012 21013 21014 21015 21016 21025 21026
      21029 21030 21031 21032 21034 21040 21041 21044 21045 21046 21047 21048 21049
      21050 21060 21070 21073 21077 21079 21080 21081 21082 21083 21084 21086 21087
      21088 21100 21110 21120 21121 21122 21123 21125 21127 21137 21138 21139 21141
      21142 21143 21145 21146 21147 21150 21151 21154 21155 21159 21160 21172 21175
      21179 21180 21181 21182 21183 21184 21188 21193 21194 21195 21196 21198 21199
      21206 21208 21209 21210 21215 21230 21235 21240 21242 21243 21244 21245 21246
      21247 21248 21249 21255 21256 21260 21261 21263 21267 21268 21270 21275 21280
      21282 21295 21296 21325 21330 21335 21336 21337 21338 21339 21340 21343 21344
      21345 21346 21347 21348 21360 21365 21366 21385 21386 21387 21390 21395 21400
      21401 21406 21407 21408 21421 21422 21423 21431 21432 21433 21435 21436 21440
      21445 21450 21451 21452 21453 21454 21461 21462 21465 21470 21485 21490 21493
      21494 21495 21497 21501 21502 21510 21552 21554 21555 21556 21557 21558 21600
      21610 21615 21616 21620 21627 21630 21632 21685 21700 21705 21720 21725 21740
      21742 21743 21750 21800 21805 21810 21820 21825 21925 21930 21931 21932 21933
      21935 21936 22010 22015 22100 22101 22102 22110 22112 22114 22206 22207 22210
      22212 22214 22220 22222 22224 22305 22310 22315 22318 22319 22325 22326 22327
      22532 22533 22548 22551 22554 22556 22558 22586 22590 22595 22600 22610 22612
      22630 22633 22800 22802 22804 22808 22810 22812 22818 22819 22830 22849 22850
      22852 22855 22856 22857 22861 22862 22864 22865 22900 22901 22902 22903 22904
      22905 23000 23020 23035 23040 23044 23066 23071 23073 23075 23076 23077 23078
      23100 23101 23105 23106 23107 23120 23125 23130 23140 23145 23146 23150 23155
      23156 23170 23172 23174 23180 23182 23184 23190 23195 23200 23210 23220 23221
      23222 23331 23332 23333 23334 23335 23395 23397 23400 23405 23406 23410 23412
      23415 23420 23430 23440 23450 23455 23460 23462 23465 23466 23470 23472 23473
      23474 23480 23485 23490 23491 23500 23505 23515 23520 23525 23530 23532 23540
      23545 23550 23552 23570 23575 23585 23600 23605 23615 23616 23620 23625 23630
      23650 23655 23660 23665 23670 23675 23680 23800 23802 23900 23920 23921 23935
      24000 24006 24066 24071 24073 24075 24076 24077 24079 24100 24101 24102 24105
      24110 24115 24116 24120 24125 24126 24130 24134 24136 24138 24140 24145 24147
      24149 24150 24151 24152 24153 24155 24160 24164 24201 24300 24301 24305 24310
      24320 24330 24331 24332 24340 24341 24342 24343 24344 24345 24346 24350 24351
      24352 24354 24356 24357 24358 24359 24360 24361 24362 24363 24365 24366 24370
      24371 24400 24410 24420 24430 24435 24470 24495 24498 24500 24505 24515 24516
      24530 24535 24538 24545 24546 24560 24565 24566 24575 24576 24577 24579 24582
      24586 24587 24600 24605 24615 24620 24635 24650 24655 24665 24666 24670 24675
      24685 24800 24802 24900 24920 24925 24930 24931 24935 24940 25000 25001 25020
      25023 25024 25025 25028 25031 25035 25040 25066 25071 25073 25075 25076 25077
      25078 25085 25100 25101 25105 25107 25109 25110 25111 25112 25115 25116 25118
      25119 25120 25125 25126 25130 25135 25136 25145 25150 25151 25170 25210 25215
      25230 25240 25248 25250 25251 25259 25260 25263 25265 25270 25272 25274 25275
      25280 25290 25295 25300 25301 25310 25312 25315 25316 25320 25332 25335 25337
      25350 25355 25360 25365 25370 25375 25390 25391 25392 25393 25394 25400 25405
      25415 25420 25425 25426 25430 25431 25440 25441 25442 25443 25444 25445 25446
      25447 25449 25450 25455 25490 25491 25492 25500 25505 25515 25520 25525 25526
      25530 25535 25545 25560 25565 25574 25575 25600 25605 25606 25607 25608 25609
      25611 25620 25622 25624 25628 25630 25635 25645 25650 25651 25652 25660 25670
      25671 25675 25676 25680 25685 25690 25695 25800 25805 25810 25820 25825 25830
      25900 25905 25907 25909 25915 25920 25922 25924 25927 25929 25931 26020 26025
      26030 26034 26035 26037 26040 26045 26055 26060 26070 26075 26080 26100 26105
      26110 26111 26113 26115 26116 26117 26118 26121 26123 26130 26135 26140 26145
      26160 26170 26180 26185 26200 26205 26210 26215 26230 26235 26236 26250 26255
      26260 26261 26262 26320 26340 26350 26352 26356 26357 26358 26370 26372 26373
      26390 26392 26410 26412 26415 26416 26418 26420 26426 26428 26432 26433 26434
      26437 26440 26442 26445 26449 26450 26455 26460 26471 26474 26476 26477 26478
      26479 26480 26483 26485 26489 26490 26492 26494 26496 26497 26498 26499 26500
      26502 26504 26508 26510 26516 26517 26518 26520 26525 26530 26531 26535 26536
      26540 26541 26542 26545 26546 26548 26550 26551 26553 26554 26555 26556 26560
      26561 26562 26565 26567 26568 26580 26585 26587 26590 26591 26593 26596 26597
      26600 26605 26607 26608 26615 26641 26645 26650 26665 26670 26675 26676 26685
      26686 26700 26705 26706 26715 26720 26725 26727 26735 26740 26742 26746 26750
      26755 26756 26765 26770 26775 26776 26785 26820 26841 26842 26843 26844 26850
      26852 26860 26862 26910 26951 26952 26990 26991 26992 27000 27001 27003 27005
      27006 27025 27027 27030 27033 27035 27036 27041 27043 27045 27047 27048 27049
      27050 27052 27054 27057 27059 27060 27062 27065 27066 27067 27070 27071 27075
      27076 27077 27078 27079 27080 27087 27090 27091 27097 27098 27100 27105 27110
      27111 27120 27122 27125 27130 27132 27134 27137 27138 27140 27146 27147 27151
      27156 27158 27161 27165 27170 27175 27176 27177 27178 27179 27181 27185 27187
      27193 27194 27200 27202 27215 27216 27217 27218 27220 27222 27226 27227 27228
      27230 27232 27235 27236 27238 27240 27244 27245 27246 27248 27252 27253 27254
      27258 27259 27265 27266 27267 27268 27269 27280 27282 27284 27286 27290 27295
      27301 27303 27305 27306 27307 27310 27315 27320 27324 27325 27326 27327 27328
      27329 27330 27331 27332 27333 27334 27335 27337 27339 27340 27345 27347 27350
      27355 27356 27357 27360 27364 27365 27372 27380 27381 27385 27386 27390 27391
      27392 27393 27394 27395 27396 27397 27400 27403 27405 27407 27409 27412 27415
      27416 27418 27420 27422 27424 27425 27427 27428 27429 27430 27435 27437 27438
      27440 27441 27442 27443 27445 27446 27447 27448 27450 27454 27455 27457 27465
      27466 27468 27470 27472 27475 27477 27479 27485 27486 27487 27488 27495 27496
      27497 27498 27499 27500 27501 27502 27503 27506 27507 27508 27509 27510 27511
      27513 27514 27516 27517 27519 27520 27524 27530 27532 27535 27536 27538 27540
      27550 27552 27556 27557 27558 27560 27562 27566 27580 27590 27591 27592 27594
      27596 27598 27600 27601 27602 27603 27604 27607 27610 27612 27614 27615 27616
      27618 27619 27620 27625 27626 27630 27632 27634 27635 27637 27638 27640 27641
      27645 27646 27647 27650 27652 27654 27656 27658 27659 27664 27665 27675 27676
      27680 27681 27685 27686 27687 27690 27691 27695 27696 27698 27700 27702 27703
      27704 27705 27707 27709 27712 27715 27720 27722 27724 27725 27726 27727 27730
      27732 27734 27740 27742 27745 27750 27752 27756 27758 27759 27760 27762 27766
      27767 27768 27769 27780 27781 27784 27786 27788 27792 27808 27810 27814 27816
      27818 27822 27823 27824 27825 27826 27827 27828 27829 27830 27831 27832 27840
      27842 27846 27848 27870 27871 27880 27881 27882 27884 27886 27888 27889 27892
      27893 27894 28003 28005 28008 28010 28011 28020 28022 28024 28030 28035 28039
      28041 28043 28045 28046 28047 28050 28052 28054 28055 28060 28062 28070 28072
      28080 28086 28088 28090 28092 28100 28102 28103 28104 28106 28107 28108 28110
      28111 28112 28113 28114 28116 28118 28119 28120 28122 28124 28126 28130 28140
      28150 28153 28160 28171 28173 28175 28192 28193 28200 28202 28208 28210 28220
      28222 28225 28226 28230 28232 28234 28238 28240 28250 28260 28261 28262 28264
      28270 28272 28280 28285 28286 28288 28289 28290 28292 28293 28294 28296 28297
      28298 28299 28300 28302 28304 28305 28306 28307 28308 28309 28310 28312 28313
      28315 28320 28322 28340 28341 28344 28345 28360 28400 28405 28406 28415 28420
      28430 28435 28436 28445 28446 28450 28455 28456 28465 28470 28475 28476 28485
      28490 28495 28496 28505 28510 28515 28525 28530 28531 28540 28545 28546 28555
      28570 28575 28576 28585 28600 28605 28606 28615 28645 28675 28705 28715 28725
      28730 28735 28737 28740 28750 28755 28760 28800 28805 28810 28820 28825 28890
      29800 29804 29805 29806 29807 29815 29819 29820 29821 29822 29823 29824 29825
      29827 29828 29830 29834 29835 29836 29837 29838 29840 29843 29844 29845 29846
      29847 29848 29850 29851 29855 29856 29860 29861 29862 29863 29866 29867 29868
      29870 29871 29873 29874 29875 29876 29877 29879 29880 29881 29882 29883 29884
      29885 29886 29887 29888 29889 29891 29892 29893 29894 29895 29897 29898 29899
      29900 29901 29902 29904 29905 29906 29907 29914 29915 29916 30115 30117 30118
      30120 30124 30125 30130 30140 30150 30160 30320 30400 30410 30420 30430 30435
      30450 30460 30462 30465 30520 30540 30545 30580 30600 30620 30630 30915 30920
      31020 31030 31032 31040 31050 31051 31070 31075 31080 31081 31084 31085 31086
      31087 31090 31200 31201 31205 31225 31230 31300 31320 31360 31365 31367 31368
      31370 31375 31380 31382 31390 31395 31400 31420 31580 31582 31584 31585 31586
      31587 31588 31590 31595 31610 31611 31613 31614 31750 31755 31760 31766 31770
      31775 31780 31781 31785 31786 31800 31805 31820 31825 31830 32035 32036 32095
      32096 32097 32098 32100 32110 32120 32124 32140 32141 32150 32151 32160 32200
      32215 32220 32225 32310 32320 32402 32440 32442 32445 32480 32482 32484 32486
      32488 32491 32500 32503 32504 32505 32520 32522 32525 32540 32650 32651 32652
      32653 32654 32655 32656 32657 32658 32659 32660 32661 32662 32663 32664 32665
      32666 32669 32670 32671 32672 32673 32800 32810 32815 32820 32851 32852 32853
      32854 32900 32905 32906 32940 33015 33020 33025 33030 33031 33050 33120 33130
      33140 33200 33201 33202 33203 33206 33207 33208 33212 33213 33214 33215 33216
      33217 33218 33220 33221 33222 33223 33227 33228 33229 33230 33231 33233 33234
      33235 33236 33237 33238 33240 33241 33242 33243 33244 33245 33246 33247 33249
      33250 33251 33253 33254 33255 33256 33261 33262 33263 33264 33265 33266 33282
      33284 33300 33305 33310 33315 33320 33321 33322 33330 33332 33335 33400 33401
      33403 33404 33405 33406 33410 33411 33412 33413 33414 33415 33416 33417 33420
      33422 33425 33426 33427 33430 33460 33463 33464 33465 33468 33470 33471 33472
      33474 33475 33476 33478 33496 33500 33501 33502 33503 33504 33505 33506 33507
      33510 33511 33512 33513 33514 33516 33533 33534 33535 33536 33542 33545 33548
      33600 33602 33606 33608 33610 33611 33612 33615 33617 33619 33620 33621 33622
      33641 33645 33647 33660 33665 33670 33675 33676 33677 33681 33684 33688 33690
      33692 33694 33697 33702 33710 33720 33722 33724 33726 33730 33732 33735 33736
      33737 33750 33755 33762 33764 33766 33767 33770 33771 33774 33775 33776 33777
      33778 33779 33780 33781 33782 33783 33786 33788 33800 33802 33803 33813 33814
      33820 33822 33824 33840 33845 33851 33852 33853 33860 33861 33863 33864 33870
      33875 33877 33880 33881 33883 33886 33910 33915 33916 33917 33918 33919 33920
      33922 33925 33926 33935 33945 33971 33974 33975 33976 33977 33978 33979 33980
      33981 33982 33983 34001 34051 34101 34111 34151 34201 34203 34401 34421 34451
      34471 34490 34501 34502 34510 34520 34530 34800 34802 34803 34804 34805 34825
      34830 34831 34832 34900 35001 35002 35005 35011 35013 35021 35022 35045 35081
      35082 35091 35092 35102 35103 35111 35112 35121 35122 35131 35132 35141 35142
      35151 35152 35161 35162 35180 35182 35184 35188 35189 35190 35201 35206 35207
      35211 35216 35221 35226 35231 35236 35241 35246 35251 35256 35261 35266 35271
      35276 35281 35286 35301 35302 35303 35304 35305 35311 35321 35331 35341 35351
      35355 35361 35363 35371 35372 35381 35501 35506 35507 35508 35509 35510 35511
      35512 35515 35516 35518 35521 35522 35523 35525 35526 35531 35533 35535 35536
      35537 35538 35539 35540 35541 35546 35548 35549 35551 35556 35558 35560 35563
      35565 35566 35570 35571 35582 35583 35585 35587 35601 35606 35612 35616 35621
      35623 35626 35631 35632 35633 35634 35636 35637 35638 35641 35642 35645 35646
      35647 35650 35651 35654 35656 35661 35663 35665 35666 35671 35691 35693 35694
      35695 35701 35721 35741 35761 35800 35820 35840 35860 35870 35875 35876 35879
      35881 35883 35884 35901 35903 35905 35907 36260 36261 36262 36818 36819 36820
      36821 36822 36823 36825 36830 36831 36832 36833 36834 36835 36838 36870 37140
      37145 37160 37180 37181 37215 37216 37217 37500 37565 37600 37605 37606 37607
      37615 37616 37617 37618 37619 37620 37650 37660 37700 37718 37720 37722 37730
      37735 37760 37761 37765 37766 37780 37785 37788 37790 38100 38101 38115 38120
      38305 38308 38380 38381 38382 38520 38525 38530 38542 38550 38555 38562 38564
      38700 38720 38724 38740 38745 38760 38765 38770 38780 38794 39000 39010 39200
      39220 39501 39502 39503 39520 39530 39531 39540 39541 39545 39560 39561 40500
      40510 40520 40525 40527 40530 40650 40652 40654 40700 40701 40702 40720 40761
      40814 40816 40818 40819 40840 40842 40843 40844 40845 41006 41007 41008 41009
      41015 41016 41017 41018 41112 41113 41114 41116 41120 41130 41135 41140 41145
      41150 41153 41155 41500 41510 41512 41520 41823 41827 41872 41874 42107 42120
      42140 42145 42200 42205 42210 42215 42220 42225 42226 42227 42235 42260 42305
      42325 42326 42335 42340 42408 42409 42410 42415 42420 42425 42426 42440 42450
      42500 42505 42507 42508 42509 42510 42600 42665 42725 42810 42815 42820 42821
      42825 42826 42830 42831 42835 42836 42842 42844 42845 42860 42870 42890 42892
      42894 42950 42953 42955 42961 42962 42970 42971 42972 43020 43030 43045 43100
      43101 43107 43108 43112 43113 43116 43117 43118 43121 43122 43123 43124 43130
      43135 43279 43280 43281 43282 43300 43305 43310 43312 43313 43314 43320 43324
      43325 43326 43327 43328 43330 43331 43332 43333 43334 43335 43336 43337 43340
      43341 43350 43351 43352 43360 43361 43400 43401 43405 43410 43415 43420 43425
      43496 43500 43501 43502 43510 43520 43605 43610 43611 43620 43621 43622 43631
      43632 43633 43634 43638 43639 43640 43641 43644 43645 43651 43652 43653 43770
      43771 43772 43773 43774 43775 43800 43810 43820 43825 43830 43831 43832 43840
      43842 43843 43845 43846 43847 43848 43850 43855 43860 43865 43870 43880 43886
      43887 43888 44005 44010 44020 44021 44025 44050 44055 44110 44111 44120 44125
      44126 44127 44130 44140 44141 44143 44144 44145 44146 44147 44150 44151 44152
      44153 44155 44156 44157 44158 44160 44180 44186 44187 44188 44200 44201 44202
      44204 44205 44206 44207 44208 44210 44211 44212 44227 44300 44310 44312 44314
      44316 44320 44322 44340 44345 44346 44602 44603 44604 44605 44615 44620 44625
      44626 44640 44650 44660 44661 44680 44700 44800 44820 44850 44900 44950 44960
      44970 45000 45020 45100 45108 45110 45111 45112 45113 45114 45116 45119 45120
      45121 45123 45126 45130 45135 45136 45150 45160 45170 45171 45172 45190 45395
      45397 45400 45402 45500 45505 45540 45541 45550 45560 45562 45563 45800 45805
      45820 45825 46040 46045 46060 46070 46200 46210 46211 46250 46255 46257 46258
      46260 46261 46262 46270 46275 46280 46285 46288 46700 46705 46707 46710 46712
      46715 46716 46730 46735 46740 46742 46744 46746 46748 46750 46751 46753 46760
      46761 46762 46930 46934 46936 46938 46945 46946 46947 47010 47015 47100 47120
      47122 47125 47130 47135 47136 47140 47141 47142 47144 47300 47350 47360 47361
      47362 47370 47371 47380 47381 47400 47420 47425 47460 47480 47510 47511 47530
      47562 47563 47564 47570 47600 47605 47610 47612 47620 47630 47700 47701 47711
      47712 47715 47716 47719 47720 47721 47740 47741 47760 47765 47780 47785 47800
      47801 47802 47900 48000 48001 48005 48020 48100 48105 48120 48140 48145 48146
      48148 48150 48152 48153 48154 48155 48180 48500 48510 48520 48540 48545 48547
      48548 48554 48556 49000 49002 49010 49020 49040 49060 49062 49085 49200 49201
      49203 49204 49205 49215 49220 49250 49255 49323 49402 49419 49425 49426 49491
      49492 49495 49496 49500 49501 49505 49507 49520 49521 49525 49540 49550 49553
      49555 49557 49560 49561 49565 49566 49570 49572 49580 49582 49585 49587 49590
      49600 49605 49606 49610 49611 49650 49651 49652 49653 49654 49655 49656 49657
      49900 49904 49906 50010 50020 50040 50045 50060 50065 50070 50075 50080 50081
      50100 50120 50125 50130 50135 50205 50220 50225 50230 50234 50236 50240 50250
      50280 50290 50320 50340 50360 50365 50370 50380 50400 50405 50500 50520 50525
      50526 50540 50541 50542 50543 50544 50545 50546 50547 50548 50562 50590 50600
      50605 50610 50620 50630 50650 50660 50700 50715 50722 50725 50727 50728 50740
      50750 50760 50770 50780 50782 50783 50785 50800 50810 50815 50820 50825 50830
      50840 50845 50860 50900 50920 50930 50940 50945 50947 50948 51020 51030 51040
      51045 51050 51060 51065 51080 51500 51520 51525 51530 51535 51550 51555 51565
      51570 51575 51580 51585 51590 51595 51596 51597 51800 51820 51840 51841 51845
      51860 51865 51880 51900 51920 51925 51940 51960 51980 51990 51992 52340 52400
      52450 52500 52510 52601 52606 52612 52614 52620 52630 52640 52647 52648 52649
      52700 53010 53040 53080 53085 53210 53215 53220 53230 53235 53240 53250 53400
      53405 53410 53415 53420 53425 53430 53431 53440 53442 53443 53444 53445 53446
      53447 53448 53449 53450 53460 53500 53502 53505 53510 53515 53520 53850 53852
      53853 53860 54110 54111 54112 54115 54120 54125 54130 54135 54205 54300 54304
      54308 54312 54316 54318 54322 54324 54326 54328 54332 54336 54340 54344 54348
      54352 54360 54380 54385 54390 54400 54401 54402 54405 54406 54407 54408 54409
      54410 54411 54415 54416 54417 54420 54430 54435 54440 54510 54512 54520 54522
      54530 54535 54550 54560 54600 54640 54650 54660 54670 54680 54690 54692 54820
      54830 54840 54860 54861 54865 54900 54901 55040 55041 55060 55110 55120 55150
      55175 55180 55200 55250 55400 55500 55520 55530 55535 55540 55550 55600 55605
      55650 55680 55720 55725 55801 55810 55812 55815 55821 55831 55840 55842 55845
      55859 55860 55862 55865 55866 55873 55875 56303 56304 56310 56314 56315 56316
      56317 56318 56320 56322 56323 56324 56340 56341 56342 56343 56344 56346 56348
      56349 56620 56625 56630 56631 56632 56633 56634 56637 56640 56805 57010 57106
      57107 57108 57109 57110 57111 57112 57120 57200 57210 57220 57230 57240 57250
      57260 57265 57268 57270 57280 57282 57283 57284 57285 57287 57288 57289 57291
      57292 57295 57296 57300 57305 57307 57308 57310 57311 57320 57330 57335 57423
      57425 57426 57520 57522 57530 57531 57540 57545 57550 57555 57556 57700 57720
      58140 58145 58146 58150 58152 58180 58200 58210 58240 58260 58262 58263 58267
      58270 58275 58280 58285 58290 58291 58292 58293 58294 58346 58400 58410 58520
      58540 58541 58542 58543 58544 58545 58546 58548 58550 58552 58553 58554 58565
      58570 58571 58572 58573 58600 58605 58660 58662 58670 58671 58672 58673 58700
      58720 58740 58750 58752 58760 58770 58800 58805 58820 58822 58825 58900 58920
      58925 58940 58943 58950 58951 58952 58953 58954 58956 58957 58958 58960 59100
      59120 59121 59130 59135 59136 59140 59150 59151 59812 59820 59821 59830 59850
      59851 59852 59855 59856 59857 59870 60200 60210 60212 60220 60225 60240 60252
      60254 60260 60270 60271 60280 60281 60500 60502 60505 60520 60521 60522 60540
      60545 60600 60605 60650 61105 61108 61120 61140 61150 61151 61154 61156 61215
      61250 61253 61304 61305 61312 61313 61314 61315 61320 61321 61322 61323 61330
      61332 61333 61334 61340 61343 61345 61440 61450 61458 61460 61470 61480 61490
      61500 61501 61510 61512 61514 61516 61518 61519 61520 61521 61522 61524 61526
      61530 61531 61533 61534 61535 61536 61537 61538 61539 61540 61541 61542 61543
      61544 61545 61546 61548 61550 61552 61553 61555 61556 61557 61558 61559 61561
      61563 61564 61566 61567 61570 61571 61575 61576 61580 61581 61582 61583 61584
      61585 61586 61590 61591 61592 61595 61596 61597 61598 61600 61601 61605 61606
      61607 61608 61613 61615 61616 61618 61619 61630 61635 61680 61682 61684 61686
      61690 61692 61697 61698 61700 61702 61703 61705 61708 61710 61711 61720 61735
      61750 61751 61760 61770 61790 61791 61793 61796 61798 61850 61855 61860 61862
      61863 61865 61867 61870 61875 61880 61885 61886 62000 62005 62010 62100 62115
      62116 62117 62120 62121 62140 62141 62142 62143 62145 62146 62147 62161 62162
      62163 62164 62165 62180 62190 62192 62200 62201 62220 62223 62225 62230 62256
      62258 62287 62292 62294 62351 63001 63003 63005 63010 63011 63012 63015 63016
      63017 63020 63030 63040 63042 63045 63046 63047 63050 63051 63055 63056 63064
      63075 63077 63081 63085 63087 63090 63101 63102 63170 63172 63173 63180 63182
      63185 63190 63191 63194 63195 63196 63197 63198 63199 63200 63250 63251 63252
      63265 63266 63267 63268 63270 63271 63272 63273 63275 63276 63277 63278 63280
      63281 63282 63283 63285 63286 63287 63290 63300 63301 63302 63303 63304 63305
      63306 63307 63600 63615 63620 63655 63660 63662 63664 63700 63702 63704 63706
      63707 63709 63710 63740 63741 63744 63746 64568 64569 64570 64573 64575 64577
      64580 64581 64702 64704 64708 64712 64713 64714 64716 64718 64719 64721 64722
      64726 64732 64734 64736 64738 64740 64742 64744 64746 64752 64755 64760 64761
      64763 64766 64771 64772 64774 64776 64782 64784 64786 64788 64790 64792 64802
      64804 64809 64818 64820 64821 64822 64823 64831 64834 64835 64836 64840 64856
      64857 64858 64861 64862 64864 64865 64866 64868 64870 64885 64886 64890 64891
      64892 64893 64895 64896 64897 64898 64905 64907 64910 64911 65091 65093 65101
      65103 65105 65110 65112 65114 65125 65130 65135 65140 65150 65155 65175 65235
      65260 65265 65272 65273 65275 65280 65285 65286 65290 65400 65420 65426 65436
      65450 65600 65710 65730 65750 65755 65756 65770 65772 65775 65780 65781 65782
      65810 65815 65820 65850 65860 65865 65870 65875 65880 65900 65920 65930 66130
      66150 66155 66160 66165 66170 66172 66174 66175 66180 66183 66185 66220 66225
      66250 66500 66505 66600 66605 66625 66630 66635 66680 66682 66700 66710 66711
      66720 66740 66762 66770 66820 66821 66825 66830 66840 66850 66852 66920 66930
      66940 66982 66983 66984 66985 66986 67005 67010 67015 67025 67027 67030 67031
      67036 67038 67039 67040 67041 67042 67043 67101 67105 67107 67108 67110 67112
      67113 67115 67120 67121 67141 67145 67208 67210 67218 67220 67227 67228 67229
      67250 67255 67311 67312 67314 67316 67318 67343 67400 67405 67412 67413 67414
      67420 67430 67440 67445 67450 67550 67560 67570 67808 67835 67880 67882 67900
      67901 67902 67903 67904 67906 67908 67909 67911 67912 67914 67915 67916 67917
      67921 67922 67923 67924 67935 67950 67961 67966 67971 67973 67974 67975 68130
      68320 68325 68326 68328 68330 68335 68340 68360 68362 68500 68505 68520 68540
      68550 68700 68720 68745 68750 68770 69110 69120 69140 69145 69150 69155 69310
      69320 69440 69450 69501 69502 69505 69511 69530 69535 69550 69552 69554 69601
      69602 69603 69604 69605 69620 69631 69632 69633 69635 69636 69637 69641 69642
      69643 69644 69645 69646 69650 69660 69661 69662 69666 69667 69670 69676 69700
      69711 69714 69715 69717 69718 69720 69725 69740 69745 69802 69805 69806 69820
      69840 69905 69910 69915 69930 69950 69955 69960 69970 77750 77761 77762 77763
      77776 77777 77778 77781 77782 77783 77784 77789 92980 92982 92986 92987 92990
      92992 92993 G0160/.freeze
    # rubocop:enable Layout/ArrayAlignment, Style/WordArray, Style/PercentLiteralDelimiters
  end
end
