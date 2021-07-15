# frozen_string_literal: true

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memoist'

# Calculator for various Quality Measures in the MassHealth Community Partners (CP) Program
# https://www.mass.gov/guides/masshealth-community-partners-cp-program-information-for-providers

# Comments reference instructions from MassHealth (our original spec) updated with the
# [QRS2021] "2021 Quality Rating System Measure Technical Specifications"
# https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
# "Calculating the Plan All-Cause Readmissions (PCR) Measure in the 2021 Adult and Health Home Core Sets"
# Technical Assistance Resource
# https://www.medicaid.gov/medicaid/quality-of-care/downloads/pcr-ta-resource.pdf
# Both As of May 28, 2021


# TODO: Calling this a Report is a misnomer now. Its really a bunch of calculators/classifiers
# and some metadata for each.
# When we next update this, we should move each measure and calculate_bh_cp* method to
# separate classes for better code readability and test-ability.
# There is some shared/reusable bits like continuously_enrolled_* and the
# various date_ranges that could be mixed or passed in to each.
# `#value_set_lookups` `#in_set?` and friends should move to the model in HL7:: namespace
# with the VALUE_SETS constant as a constructor for it, since "Value Sets" and "Code Systems"
# are useful concepts for all HL7-based medical coding.

module ClaimsReporting
  class QualityMeasuresReport
    extend Memoist

    include ActiveModel::Model

    include HmisFilters

    # Base Range<Date> for this report. Some measures define derived ranges
    # Most of the measures assume this is a Calendar year in their calculations
    # and expectations around health insurance etc.
    attr_reader :date_range

    # The Measure#id s we want to calculate. Defaults to all AVAILABLE_MEASURES.keys
    attr_reader :measures

    # An optional ::Filters::QualityMeasuresFilter to apply to the data.
    attr_reader :filter

    # This report is normally run against a medicaid plan year...
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

    Measure = Struct.new(
      :id,
      :title,
      :desc,
      :numerator,
      :denominator,
      keyword_init: true,
    )
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
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age who initiate/engage with AOD treatment.',
        denominator: 'BH CP enrollees 18 to 64 years of age with a new episode of AOD during the intake period.',
      ),
      Measure.new(
        id: :bh_cp_8,
        title: 'BH CP #8: Engagement of Alcohol, Opioid, or Other Drug Abuse or Dependence Treatment - % events',
        desc: <<~MD,
          <mark>**Note**: This measure requires AOD claims data which are currently not available.</mark>
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age who initiate/engage with AOD treatment.',
        denominator: 'BH CP enrollees 18 to 64 years of age with a new episode of AOD during the intake period.',
      ),
      Measure.new(
        id: :bh_cp_9,
        title: 'BH CP #9: Follow-Up After Hospitalization for Mental Illness (7 days) - % events',
        desc: <<~MD,
          The percentage of discharges for Behavioral Health Community
          Partner (BH CP) enrollees 18 to 64 years of age who were hospitalized
          for treatment of selected mental illness or intentional self-harm
          diagnoses and who received a follow-up visit with a mental health
          practitioner within 7 days of discharge.
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age who had a follow-up visit with a mental health practitioner within 7 calendar days after discharge.',
        denominator: 'BH CP enrollees 18 to 64 years of age as of the date of discharge.',
      ),
      Measure.new(
        id: :bh_cp_10,
        title: 'BH CP #10: Diabetes Screening for Individuals With Schizophrenia or Bipolar Disorder Who Are Using Antipsychotic Medications',
        desc: <<~MD,
          The percentage of Behavioral Health Community Partner (BH CP)
          enrollees 18 to 64 years of age with schizophrenia,
          schizoaffective disorder or bipolar disorder, who were
          dispensed an antipsychotic medication and had a diabetes
          screening test during the measurement year.
        MD
        numerator: 'BH CP enrollees 18 to 64 years of age with schizophrenia, schizoaffective disorder or bipolar disorder, who were dispensed an antipsychotic medication and received a diabetes screening test during the measurement year.',
        denominator: 'BH CP enrollees 18 to 64 years of age with schizophrenia, schizoaffective disorder or bipolar disorder and were dispensed an antipsychotic medication during the measurement year.',
      ),
      Measure.new(
        id: :bh_cp_12,
        title: 'BH CP #12: Emergency Department Visits for Adults with Mental Illness, Addiction, or Co-occurring Conditions',
        desc: <<~MD,
          <mark>**Note**: This measure requires AOD claims data which are currently not available.</mark>
        MD
        numerator: 'Number of emergency department visits made by BH CP enrollees 18 to 64 years of age with serious mental illness and/or substance addiction.',
        denominator: 'BH CP enrollees 18 to 64 years of age who are identified with serious mental illness and/or substance addiction',
      ),
      Measure.new(
        id: :bh_cp_13,
        title: 'BH CP #13: Hospital Readmissions (Adult)',
        desc: <<~MD,
          For Behavioral Health Community Partner (BH CP) enrollees 18 to 64
          years of age, the number of acute inpatient stays during the
          measurement year that were followed by an unplanned acute readmission
          for any diagnosis within 30 days and the predicted probability of an
          acute readmission. Data are reported in the following categories:

          1. Count of Index Hospital Stays (IHS) (denominator)
          2. Count of Observed 30-Day Readmissions (numerator)
          3. Count ofExpected 30-Day Readmissions
        MD
        numerator: 'The number of 30-day readmissions for BH CP enrollees.',
        denominator: 'The number of Index Hospital Stays for BH CP enrollees.',
      ),
      Measure.new(
        id: :bh_cp_13a,
        title: 'BH CP #13: Hospital Readmissions (Adult): Enrollees with 1-3 stays',
        desc: '',
        numerator: '',
        denominator: '',
      ),
      Measure.new(
        id: :bh_cp_13b,
        title: 'BH CP #13: Hospital Readmissions (Adult): Enrollees with 4+ stays',
        desc: '',
        numerator: '',
        denominator: '',
      ),
      Measure.new(
        id: :assigned_enrollees,
        title: 'Selected Assigned Enrollees',
      ),
      Measure.new(
        id: :medical_claims,
        title: 'Selected Medical Service Claims',
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
    # TODO: Refactor into {measure_id, row_id, value, ....}
    # it turns out we almost never get to derive more than one measure
    # from a single row so the meta-programmed fields are wasted space
    # and brain power and in a few cases the value held is not the
    # tri-state flag described above
    MeasureRow = Struct.new(
      :row_type,
      :row_id,
      :variance, # only used by BH_CP_13 Risk Assessment now
      :expected_value, # only used by BH_CP_13 Risk Assessment now
      *AVAILABLE_MEASURES.keys,
      keyword_init: true,
    )

    def serializable_hash
      measure_info = AVAILABLE_MEASURES.values.map do |m|
        numerator, denominator = * if respond_to?(m.id)
                                     send(m.id)
                                   else
                                     percentage medical_claim_based_rows, m.id
        end

        # only one value indicates a count
        if denominator.present?
          value = (numerator.to_f / denominator) unless denominator.zero?
        else
          value = numerator
          numerator = nil
        end

        # any detail tables?
        detail_table_msg = "#{m.id}_table"
        [m.id, {
          id: m.id,
          title: m.title,
          numerator: numerator,
          denominator: denominator,
          value: value,
          table: (send(detail_table_msg) if respond_to?(detail_table_msg)),
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

    # Members assigned to a BH CP on or between September 2nd of the year prior to the
    # measurement year and September 1st of the measurement year.
    def cp_enollment_date_range
      # Handle "September"
      # The usually measurement year is Jan 1 - Dec 31 so we shift back by three named months and add a day
      (date_range.min << 4) + 1.day .. (date_range.max << 4) + 1.day
    end

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

      progress_proc = if ENV['CLAIMS_REPORTING_SHOW_PROGRESS']
        require 'progress_bar'
        pb = ProgressBar.new(medical_claims_by_member_id.size, :counter, :bar, :percentage, :rate, :eta)
        ->(_item, _i, _result) { pb.increment! }
      end

      logger.debug { "#{medical_claims_scope.count} medical_claims" }

      value_set_lookups # preload before we potentially fork to save IO/ram

      rows = Parallel.flat_map(
        medical_claims_by_member_id,
        # we can spread the work below across many CPUS by removing
        # the in_threads and running in_processes
        # There is very little I/O so using in_threads wont help much till Ruby 3 Ractor (or other GIL workarounds)
        in_processes: 1,
        finish: progress_proc,
      ) do |member_id, claims|
        # we ideally do zero database calls in here

        rows = []
        member = members_by_member_id[member_id]
        enrollments = enrollments_by_member_id.fetch(member_id)

        if measures.include?(:bh_cp_1) || measures.include?(:bh_cp_2)
          date_of_birth = member.date_of_birth

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

    private def in_set?(vs_name, claim, dx1_only: false)
      codes_by_system = value_set_lookups.fetch(vs_name) do
        raise "Value Set '#{vs_name}' is unknown"
        #{}
      end
      raise "Value Set '#{vs_name}' has no codes defined" if codes_by_system.empty?

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

      if (code_pattern = codes_by_system['ICD9PCS'])
        return trace_set_match!(vs_name, claim, :ICD9PCS) if claim.matches_icd9pcs? code_pattern
      end
    end

    private def rx_in_set?(vs_name, claim)
      codes_by_system = value_set_lookups.fetch(vs_name)

      # TODO? RxNorm, CVX might also show up lookup code but we dont have any claims data with that info, nor a crosswalk handy
      # TODO? raise/warn on an unrecognised code_system_name?

      if (ndc_codes = codes_by_system['NDC']).present?
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
        # puts 'BH_CP_10: At least one inpatient....'
        return true
      end

      # > At least two of the following, on different dates of service, with or without a telehealth modifier (Telehealth Modifier Value Set)
      visits = claims_with_dx.select do |c|
        in_set?('Visit Setting Unspecified', c) && (
          in_set?('Acute Inpatient POS', c) ||
          in_set?('Community Mental Health Center POS', c) ||
          in_set?('ED POS', c) ||
          in_set?('Nonacute Inpatient POS', c) ||
          in_set?('Partial Hospitalization POS', c) ||
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
        # puts 'BH_CP_10: At least two Schizophrenia....'
        return true
      end

      # > or both encounters have any diagnosis of bipolar disorder (Bipolar Disorder Value Set; Other Bipolar Disorder Value Set).
      if visits.select { |c| in_set?('Bipolar Disorder', c) || in_set?('Other Bipolar Disorder', c) }.uniq(&:service_start_date).size >= 2
        # puts 'BH_CP_10: At least two Bipolar....'
        return true
      end

      return false
    end

    private def diabetes?(claims, rx_claims)
      # There are two ways to identify members with
      # diabetes: by claim/encounter data and by pharmacy data.  The
      # organization must use both methods to identify enrollees with
      # diabetes, but an enrollee need only be identified by one method to be
      # excluded from the measure. Enrollees may be identified as having
      # diabetes during the measurement year or the year prior to the
      # measurement year.

      # Claim/encounter data. Enrollees who met at any of the following
      # criteria during the measurement year or the year prior to the
      # measurement year (count services that occur over both years).

      inpatient_diabetes = claims.any? do |c|
        #   - At least one acute inpatient encounter (Acute Inpatient Value Set)
        #   with a diagnosis of diabetes (Diabetes Value Set) without (Telehealth
        #   Modifier Value Set; Telehealth POS Value Set).
        (
          in_set?('Acute Inpatient', c) && in_set?('Diabetes', c) && !(
            in_set?('Telehealth Modifier', c) || in_set?('Telehealth POS', c)
          )
        )
      end
      return true if inpatient_diabetes

      #   - At least two outpatient visits (Outpatient Value Set), observation
      #   visits (Observation Value Set), ED visits (ED Value Set) or nonacute
      #   inpatient encounters (Nonacute Inpatient Value Set) on different dates
      #   of service, with a diagnosis of diabetes (Diabetes Value Set). Visit
      #   type need not be the same for the two encounters.
      #
      #   Only include nonacute inpatient encounters (Nonacute Inpatient Value
      #   Set) without telehealth (Telehealth Modifier Value Set; Telehealth POS
      #   Value Set).
      outpatient_claims = claims.select do |c|
        in_set?('Diabetes', c) && (
          in_set?('Outpatient', c) ||
          in_set?('Observation', c) ||
          in_set?('ED', c) ||
          (
            in_set?('Nonacute Inpatient', c) && !(
              in_set?('Telehealth Modifier', c) || in_set?('Telehealth POS', c)
            )
          )
        )
      end

      #   Only one of the two visits may be a telehealth visit, a telephone
      #   visit or an online assessment. Identify telehealth visits by the
      #   presence of a telehealth modifier (Telehealth Modifier Value Set) or
      #   the presence of a telehealth POS code (Telehealth POS Value Set)
      #   associated with the outpatient visit. Use the code combinations below
      #   to identify telephone visits and online assessments:
      #
      #   – A telephone visit (Telephone Visits Value Set) with any diagnosis of
      #   diabetes (Diabetes Value Set).
      #
      #   – An online assessment (Online Assessments Value Set) with any diagnosis
      #   of diabetes (Diabetes Value Set).
      remote_claims = outpatient_claims.select do |c|
        in_set?('Telephone Visits', c) || in_set?('Online Assessments', c)
      end
      return true if outpatient_claims.size > 2 && !( outpatient_claims - remote_claims).empty?

      # – Pharmacy data. Enrollees who were dispensed insulin or oral
      #   hypoglycemics/antihyperglycemics during the measurement year or
      #   year prior to the measurement year on an ambulatory basis (Diabetes Medications List).
      #   TODO: on an ambulatory basis????
      #   Cant find docs on calculating this but I'm betting we can do something by looking for
      #   overlapping inpatient stays
      diabetes_rx = rx_claims.detect do |c|
        measurement_and_prior_year.cover?(c.service_start_date) && rx_in_set?('Diabetes Medications', c)
      end
      if diabetes_rx
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
      # There no longer appears to bea  "Long-Acting Injections" Value Set
      # for medical claims data
    end

    # Diabetes Screening for Individuals With Schizophrenia or Bipolar Disorder Who Are Using Antipsychotic Medications
    private def calculate_bh_cp_10(member, claims, rx_claims, enrollments)
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

      # puts "BH_CP_10: MemberRoster#id=#{member.id} Found schizophrenia or bipolar disorder DX"
      # puts "BH_CP_10: MemberRoster#id=#{member.id} Checking #{rx_claims.size} Rx Claims"

      # Exclude enrollees who met any of the following criteria:

      # Enrollees with diabetes.
      if diabetes?(claims, rx_claims)
        trace_exclusion do
          "BH_CP_10: Exclude MemberRoster#id=#{member.id} has diabetes"
        end
        return []
      end
      # NOT taking antipsychotics
      unless antipsychotic_meds?(claims, rx_claims)
        trace_exclusion do
          "BH_CP_10: Exclude MemberRoster#id=#{member.id} not taking anti-psychotics"
        end
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

      # puts "BH_CP_10: MemberRoster#id=#{member.id}. Checking #{covered_ranges.size} periods"

      covered_ranges.each do |required_range|
        # puts "BH_CP_10: MemberRoster#id=#{member.id}. Checking #{required_range} enrollment period"
        unless continuously_enrolled_cp?(enrollments, required_range, min_days: 122)
          trace_exclusion { "BH_CP_10: MemberRoster#id=#{member.id} must be continuously enrolled with a BH CP for at least 122 calendar days. required_mh_range: #{required_mh_range}" }
          return []
        end
        unless continuously_enrolled_mh?(enrollments, required_range, max_gap: 45)
          trace_exclusion { "BH_CP_10: MemberRoster#id=#{member.id} must be continuously enrolled in MassHealth. required_mh_range: #{required_mh_range}" }
          return []
        end

        diabetes_screening = claims.detect do |c|
          # RE: CPT_GLUCOSE The spec called for a "Glucose Tests" Value Set
          # which I could not find. That said there are only a few Glucose test
          # CPT codes and we don't have lab data so we cant use LOINC
          required_range.cover?(c.service_start_date) && (
            in_set?('HbA1c Tests', c) || c.procedure_code.in?(CPT_GLUCOSE)
          )
        end
        # puts "BH_CP_10: Found MemberRoster#id=#{member.id} diabetes_screening=#{diabetes_screening.present?}"
        row = MeasureRow.new(
          row_type: 'enrollee',
          row_id: "#{member.id}-#{required_range.min}-#{required_range.max}",
          bh_cp_10: diabetes_screening.present?,
        )
        rows << row
      end

      rows
    end

    # 82947 Glucose; quantitative, blood (except reagent strip)
    # 82948 Glucose; blood, reagent strip
    # 82962 Glucose; blood by glucose monitoring device(s) cleared by the FDA specifically for home use
    CPT_GLUCOSE = ['82947', '82948', '82962']

    # BH CP #13: Hospital Readmissions (Adult)
    private def calculate_bh_cp_13(member, claims, enrollments) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

      # > Step 1: Identify all acute inpatient discharges [and observation stay discharges] on or between January 1
      # and December 1 of the measurement year
      # We select discharges for the whole year and filter later because we we need overlapping but different
      # Discharge ranges for both the Numerator and denominator
      #
      # [QRS2021] added "observation stay discharges"
      acute_inpatient_claims = claims.select do |c|
        c.discharge_date.present? && measurement_year.cover?(c.discharge_date) && (
          acute_inpatient_stay?(c) || in_set?('Observation Stay', c)
        )
      end.sort_by(&:service_start_date)

      # > Step 2: Acute-to-acute direct transfers
      # > A direct transfer is when the discharge date from the first inpatient setting precedes
      # > the admission date to a second inpatient setting by one calendar day or less.

      # so we split this history into "stays" that include any direct transfers
      acute_inpatient_stays = acute_inpatient_claims.slice_when do |c1, c2|
        # and add fall backs for Observation Stays which dont have admit_date
        c2_start_date = c2.admit_date || c2.service_start_date
        c1_end_date = c1.discharge_date || c1.service_end_date
        (c2_start_date - c1_end_date) > 1
      end.to_a

      n_stays = acute_inpatient_stays.size
      raise 'Too many stays to check' if n_stays > 1000

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

        # > Step 5: Calculate continuous enrollment.
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

        row_id = "#{admit.id}-#{discharge.id}"

        ra = bh_cp_13_ihs_risk_adjustment(member, stay_claims, claims)

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
              in_set?('Rehabilitation', c, dx1_only: true) ||
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
          row_id: row_id,
          bh_cp_13: readmitted_in_30_days,
          variance: (ra[:variance] if ra),
          expected_value: (ra[:expected_readmit_rate] if ra),
        )
        rows << row
      end

      if rows.size.between?(1, 3)
        rows.each do |r|
          r.bh_cp_13a = r.bh_cp_13
        end
      elsif rows.size >= 4
        rows.each do |r|
          r.bh_cp_13b = r.bh_cp_13
        end
      end

      rows
    end

    # An array of arrays describing a table of details for the measure
    def bh_cp_13_table
      measure_rows = medical_claim_based_rows

      table_rows = {
        bh_cp_13: 'All Enrollees',
        bh_cp_13a: 'Enrollee had 1-3 index hospital stays',
        bh_cp_13b: 'Enrollee had 4+ index hospital stays',
      }

      cols = {
        numerator: 'Numerator (Number of observed IHS with a readmission within 30 days of discharge)',
        denominator: 'Denominator (Count the number of IHS)',
        value: 'Observed Readmission Rate',
        expected_count: 'Count of Expected 30-Day Readmissions',
        expected_value: 'Expected Readmission Rate',
        variance: 'Variance',
        oe_ratio: 'O/E Ratio',
      }

      table = [
        ['Frequency of Index Hospital Stays'],
        [''] + cols.values,
      ]

      table_rows.each do |measure_id, row_heading|
        numerator, denominator = * percentage(measure_rows, measure_id)
        value = (numerator.to_f / denominator) if numerator && denominator&.positive?

        if value
          selected_rows = rows_for_measure(measure_rows, measure_id)
          expected_count = 0
          variance = 0
          selected_rows.each do |row|
            # Note: The confusing names are in the spec
            # > The Count of Expected Readmissions is the sum of the Estimated Readmission Risk calculated in step 6 for each IHS
            expected_count += row.expected_value if row.expected_value
            # > Calculate the total (sum) variance for each age group.
            variance += row.variance if row.variance
          end

          # > Expected Readmission Rate:
          # > The Count of Expected 30-Day Readmissions divided by the Count of Index Stays
          # The spec says devided by the math only makes sense if you multiply
          expected_value = expected_count / denominator

          # > O/E Ratio: The Count of Observed 30-Day Readmissions
          # > divided by the Count of Expected 30-Day Readmissions calculated by IDSS.
          oe_ratio = numerator.to_f / expected_count if expected_count.positive?
        else
          expected_value = nil
          variance = nil
          expected_count = nil
          oe_ratio = nil
        end

        table << [
          row_heading,
          numerator,
          denominator,
          # > Round to four decimal places using the .5 rule
          value&.round(4),
          expected_count&.round(4),
          expected_value&.round(4),
          variance&.round(4),
          oe_ratio&.round(4),
        ]
      end

      table
    end
    memoize :bh_cp_13_table

    private def pcr_risk_adjustment_calculator
      ::ClaimsReporting::Calculators::PcrRiskAdjustment.new
    rescue StandardError => e
      logger.warn { "PcrRiskAdjustment calculator is unavailable: #{e.message}" }
      nil
    end
    memoize :pcr_risk_adjustment_calculator

    private def bh_cp_13_ihs_risk_adjustment(member, stay_claims, claims)
      return unless pcr_risk_adjustment_calculator

      # Since we are now user 2021 QRS Plan All-Cause Readmissions (PCR)
      # as the spec for risk adjustment date We are using
      # the methods for that.
      # See https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
      # ClaimsReporting::Calculators::PcrRiskAdjustment

      discharge_date = stay_claims.last.discharge_date
      discharge_dx_code = stay_claims.first.dx_1

      # > Step 1
      # > Identify all diagnoses for encounters during the classification period. Include the following when identifying encounters:
      comorb_dx_codes = Set.new
      claims.each do |c|
        # > • Outpatient visits (Outpatient Value Set).
        # > • Telephone visits (Telephone Visits Value Set)
        # > • Observation visits (Observation Value Set).
        # > • ED visits (ED Value Set).
        # > • Inpatient events:
        # > – Nonacute inpatient encounters (Nonacute Inpatient Value Set).
        # > – Acute inpatient encounters (Acute Inpatient Value Set).
        # > – Acute and nonacute inpatient discharges (Inpatient Stay Value Set).

        # > Use the date of service for outpatient, observation and ED visits. Use the discharge date for inpatient events.
        date = if in_set?('Outpatient', c) ||
          in_set?('Telephone Visits', c) ||
          in_set?('Observation', c)

          c.service_start_date
        elsif in_set?('ED', c) ||
          in_set?('Nonacute Inpatient', c) ||
          in_set?('Acute Inpatient', c)

          c.discharge_date
        end

        next unless date.present? && measurement_year.cover?(date)

        comorb_dx_codes += c.dx_codes
      end
      # > Exclude the primary discharge diagnosis on the IHS.
      comorb_dx_codes -= [discharge_dx_code]

      # > Step 3 Assign each diagnosis to a comorbid Clinical Condition (CC)
      # > category using Table CC— Comorbid. If the code appears more than once
      # > in Table CC—Comorbid, it is assigned to multiple CCs.
      # >All digits must match
      # > exactly when mapping diagnosis codes to the comorbid CCs.
      comorb_cc_codes = comorb_dx_codes.map do |dx_code|
        pcr_risk_adjustment_calculator.cc_mapping[dx_code]
      end.compact

      # > Exclude all diagnoses that cannot be assigned to a comorbid CC category. For
      # > members with no qualifying diagnoses from face-to-face encounters,
      # > skip to the Risk Adjustment Weighting section.
      return unless comorb_cc_codes.any?

      had_surgery = stay_claims.any? do |c|
        in_set?('Surgery Procedure', c)
      end
      observation_stay = stay_claims.any? do |c|
        in_set?('Observation Stay', c)
      end

      pcr_risk_adjustment_calculator.process_ihs(
        age: GrdaWarehouse::Hud::Client.age(dob: member.date_of_birth, date: discharge_date),
        gender: member.sex, # they mean biological sex
        observation_stay: observation_stay,
        had_surgery: had_surgery,
        discharge_dx_code: discharge_dx_code,
        comorb_dx_codes: comorb_dx_codes,
      ).tap do |result|
        # debug_prefix = " BH_CP_13: MemberRoster#id=#{member.id} stay=#{stay_claims.first.id}"
        # puts "#{debug_prefix} Risk adjustment data #{result.inspect}" unless result[:sum_of_weights].zero?
      end
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

    private def rows_for_measure(enumerable, flag)
      enumerable.reject do |r|
        r.send(flag).nil?
      end
    end

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

    # Map the names used in the various CMS Quality Rating System specs
    # to the OIDs. Names will not be unique in Hl7::ValueSetCode as we load
    # other sources
    # Note: We were missing names used in BH CP 10 from the standard sources
    # so a custom list from our TA partner was loaded under the non-standard
    # 'x.' placeholder OIDs
    # - Schizophrenia
    # - Bipolar Disorder
    # - Other Bipolar Disorder
    # - BH Stand Alone Acute Inpatient
    # - BH Stand Alone Nonacute Inpatient
    # - Nonacute Inpatient POS
    # - Long-Acting Injections - see note near "Long Acting Injections" in MEDICATION_LISTS
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
    VALUE_SETS = MEDICATION_LISTS.merge({
      'Acute Condition' => '2.16.840.1.113883.3.464.1004.1324',
      'Acute Inpatient' => '2.16.840.1.113883.3.464.1004.1810',
      'Acute Inpatient POS' => '2.16.840.1.113883.3.464.1004.1027',
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
      'Observation Stay' => '2.16.840.1.113883.3.464.1004.1461',
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
      'Surgery Procedure' => '2.16.840.1.113883.3.464.1004.2223',
      'Telehealth Modifier' => '2.16.840.1.113883.3.464.1004.1445',
      'Telehealth POS' => '2.16.840.1.113883.3.464.1004.1460',
      'Telephone Visits' => '2.16.840.1.113883.3.464.1004.1246',
      'Transitional Care Management Services' => '2.16.840.1.113883.3.464.1004.1462',
      'Visit Setting Unspecified' => '2.16.840.1.113883.3.464.1004.1493',
      'Well-Care' => '2.16.840.1.113883.3.464.1004.1262',
      'Schizophrenia' => 'x.Schizophrenia',
      'Bipolar Disorder' => 'x.Bipolar Disorder',
      'Other Bipolar Disorder' => 'x.Other Bipolar Disorder',
      'BH Stand Alone Acute Inpatient' => 'x.BH Stand Alone Acute Inpatient',
      'BH Stand Alone Nonacute Inpatient' => 'x.BH Stand Alone Nonacute Inpatient',
      'Nonacute Inpatient POS' => 'x.Nonacute Inpatient POS',
    }).freeze
  end
end
