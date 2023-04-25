###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class AgencyPerformance
    include ArelHelper

    attr_accessor :range
    def initialize range:, agency_scope: nil
      @range = (range.first.to_date..range.last.to_date)
      @agency_scope = agency_scope
    end

    def self.url
      'warehouse_reports/health/agency_performance'
    end

    DESCRIPTIONS = {
      without_required_qa: 'Patients who have not completed intake and have not received a QA in the specified date range.',
      without_required_f2f_visit: 'Patients who have not received a face-to-face visit in the two months preceding the specified end date.',
      with_discharge_followup_completed: 'Number of discharge follow-up QAs within the specified data range.',
      with_completed_intake: 'Patients with completed initial intake (Consent, Comp Assessment, HRSN, and Care Plan) as of the specified end date.',
      initial_intake_due: 'Patients who need to receive an initial intake within 30 days of the specified end date.',
      initial_intake_overdue: 'Patients who did not complete an initial intake within 153 days of their enrollment as of the earlier of the current date or the specified end date.',
      intake_renewal_due: 'Patients who need to receive a renewal intake within 30 days of the specified end date.',
      intake_renewal_overdue: 'Patients who did not receive a renewal intake within 365 days of their last intake as of the earlier of the current date or the specified end date.',
      without_required_wellcare_visit: 'Patients that did not have a comprehensive well-care visit with a PCP or an OB/GYN practitioner within 12 months of the earlier of the current date or the specified end date. Such visits are identified by paid claims, as specified by the Mathematica Annual Well-Care Visits Measure calculation. *NOTE:* Claims data is approximately 3 months out of date, so any annual well care visits that occured in the past 3 months may not be included.',
    }.freeze

    def agency_counts
      @agency_counts ||= agencies.map do |id, name|
        patient_ids = patient_referrals.select do |_, (agency_id, _)|
          agency_id == id
        end.keys

        next unless patient_ids.any?

        OpenStruct.new(
          {
            id: id,
            name: name,
            patient_referrals: patient_ids,
            without_required_qa: patient_ids - with_required_qa,
            without_required_f2f_visit: patient_ids - with_required_f2f_visit,
            with_discharge_followup_completed: with_discharge_followup_completed.select { |p_id| p_id.in?(patient_ids) },
            with_completed_intake: with_completed_intake.select { |p_id| p_id.in?(patient_ids) },
            initial_intake_due: initial_intake_due.select { |p_id| p_id.in?(patient_ids) },
            initial_intake_overdue: initial_intake_overdue.select { |p_id| p_id.in?(patient_ids) },
            intake_renewal_due: intake_renewal_due.select { |p_id| p_id.in?(patient_ids) },
            intake_renewal_overdue: intake_renewal_overdue.select { |p_id| p_id.in?(patient_ids) },
            without_required_wellcare_visit: patient_ids - with_required_wellcare_visit,
          },
        )
      end.compact
    end

    def total_counts
      @total_counts ||= OpenStruct.new(
        {
          id: nil,
          name: 'Totals',
          # Sum numeric columns
          # drop(2) removes id and name
          **agency_counts.first&.to_h&.keys&.drop(2)&.map { |key| [key, agency_counts.map { |o| o[key] }.reduce(&:+)] }.to_h,
        },
      )
    end

    def agencies
      @agencies ||= agency_scope.pluck(:id, :name).to_h
    end

    def agency_scope
      @agency_scope || Health::Agency.all
    end

    def client_ids
      @client_ids ||= Health::Patient.where(id: patient_referrals.keys).
        pluck(:client_id, :id).to_h
    end

    def patient_referrals
      @patient_referrals ||= Health::PatientReferral.with_patient.
        where.not(agency_id: nil).
        active_within_range(start_date: @range.first, end_date: @range.last).
        joins(:patient).
        where(agency_id: agency_scope.select(:id)).
        pluck(:patient_id, :agency_id, hpr_t[:enrollment_start_date]).
        reduce({}) do |hash, (patient_id, agency_id, enrollment_start_date)|
          hash.update(patient_id => [agency_id, enrollment_start_date])
        end
    end

    def patient_ids
      @patient_ids ||= patient_referrals.keys
    end

    def with_required_qa
      @with_required_qa ||= Health::QualifyingActivity.
        payable.
        not_valid_unpayable.
        where(patient_id: patient_ids).
        in_range(@range.last - 60.days .. @range.last).
        pluck(:patient_id).uniq
    end

    def with_required_f2f_visit
      @with_required_f2f_visit ||= Health::QualifyingActivity.
        payable.
        not_valid_unpayable.
        face_to_face.
        where(patient_id: patient_ids).
        in_range(@range.last - 60.days .. @range.last).
        pluck(:patient_id).uniq
    end

    def with_discharge_followup_completed
      @with_discharge_followup_completed ||= Health::QualifyingActivity.
        submittable.
        where(patient_id: patient_ids).
        in_range(@range).
        where(activity: :discharge_follow_up).
        pluck(:patient_id).uniq
    end

    def with_completed_intake
      @with_completed_intake ||= Health::Patient.
        joins(:careplans).
        where(h_cp_t[:careplan_sent].eq(true)).
        distinct.
        pluck(hp_t[:id])
    end

    def with_initial_intake
      @with_initial_intake ||= Health::Patient.
        where(id: patient_ids).
        joins(:careplans).
        where(h_cp_t[:careplan_sent].eq(true)).
        order(h_cp_t[:careplan_sent_on].desc).
        pluck(hp_t[:id], h_cp_t[:careplan_sent_on]).to_h
    end

    def initial_intake_due
      overdue = [@range.last, Date.current].min
      @initial_intake_due ||= Health::Patient.
        where(id: patient_ids).
        where.not(id: with_initial_intake.keys).
        where(engagement_date: overdue - 30.days .. overdue)
    end

    def initial_intake_overdue
      overdue = [@range.last, Date.current].min
      @initial_intake_overdue ||= Health::Patient.
        where(id: patient_ids).
        where.not(id: with_initial_intake.keys).
        where(engagement_date: ...overdue)
    end

    def intake_renewal_due
      @intake_renewal_due ||= Health::Patient.
        where(id: patient_ids).
        joins(:recent_pctp_form).
        where(h_cp_t[:careplan_sent_on].between(@range.last - 1.year - 30.days .. @range.last - 1.year))
    end

    def intake_renewal_overdue
      overdue = [@range.last, Date.current].min - 1.year
      @intake_renewal_overdue = Health::Patient.
        where(id: patient_ids).
        joins(:recent_pctp_form).
        where(h_cp_t[:careplan_sent_on].lt(overdue))
    end

    def with_required_wellcare_visit
      @with_required_wellcare_visit ||= ClaimsReporting::MedicalClaim.
        annual_well_care_visits.
        service_in(Date.today - 12.months...Date.today).
        joins(:patient).
        where(hp_t[:id].in(patient_referrals.keys)).
        pluck(hp_t[:id]).uniq
    end
  end
end
