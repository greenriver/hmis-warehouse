###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class AgencyPerformance < PerformanceBase
    include ArelHelper

    def initialize range:, agency_scope: nil
      @range = (range.first.to_date..range.last.to_date)
      @agency_scope = agency_scope
    end

    def self.url
      'warehouse_reports/health/agency_performance'
    end

    DESCRIPTIONS = {
      without_required_qa: "Patients with no QA in the last #{QA_WINDOW.inspect}, or, who have not completed intake and have not received a QA in the #{QA_NO_INTAKE_WINDOW.inspect} preceding the specified end date.",
      without_required_f2f_visit: "Patients who have not received a face-to-face visit in the #{F2F_WINDOW.inspect} preceding the specified end date.",
      with_discharge_followup_completed: 'Number of discharge follow-up QAs within the specified data range.',
      with_completed_intake: 'Patients with completed initial intake (Consent, Comp Assessment, HRSN, and Care Plan) as of the specified end date.',
      initial_intake_due: "Patients who need to receive an initial intake within #{COMPLETION_WINDOW.inspect} of the specified end date.",
      initial_intake_overdue: "Patients who did not complete an initial intake within #{Health::PatientReferral::ENGAGEMENT_IN_DAYS.inspect} of their enrollment as of the earlier of the current date or the specified end date.",
      intake_renewal_due: "Patients who need to receive a renewal intake within #{COMPLETION_WINDOW.inspect} of the specified end date.",
      intake_renewal_overdue: "Patients who did not receive a renewal intake within #{RENEWAL_WINDOW.inspect} of their last intake as of the earlier of the current date or the specified end date.",
      without_required_wellcare_visit: "Patients that did not have a comprehensive well-care visit with a PCP or an OB/GYN practitioner within #{WELLCARE_WINDOW.inspect} of the earlier of the current date or the specified end date. Such visits are identified by paid claims, as specified by the Mathematica Annual Well-Care Visits Measure calculation. *NOTE:* Claims data is approximately 3 months out of date, so any annual well care visits that occured in the past 3 months may not be included.",
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
            without_required_qa: patient_ids - with_completed_intake - with_required_qa,
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
  end
end
