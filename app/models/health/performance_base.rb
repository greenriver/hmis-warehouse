###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PerformanceBase
    include ArelHelper

    QA_WINDOW = 60.days
    QA_NO_INTAKE_WINDOW = 30.days
    F2F_WINDOW = 60.days
    COMPLETION_WINDOW = 30.days
    RENEWAL_WINDOW = 365.days
    WELLCARE_WINDOW = 12.months

    attr_accessor :range

    def client_ids
      @client_ids ||= Health::Patient.where(id: patient_referrals.keys).
        pluck(:client_id, :id).to_h
    end

    def patient_ids
      @patient_ids ||= patient_referrals.keys
    end

    def with_required_qa
      @with_required_qa ||=
        patient_ids - Health::Patient.needs_qa(on: @range.last).pluck(:id)
    end

    def with_required_f2f_visit
      @with_required_f2f_visit ||= patient_ids - Health::Patient.needs_f2f(on: @range.last).pluck(:id)
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
        has_intake.
        pluck(:id)
    end

    def with_initial_intake
      @with_initial_intake ||= Health::Patient.
        preload(recent_pctp_careplan: :instrument).
        where(id: patient_ids).
        has_intake.
        reject { |patient| patient.recent_pctp_careplan.nil? }.
        map { |patient| [patient.id, patient.recent_pctp_careplan.instrument.careplan_sent_on] }.to_h
    end

    def initial_intake_due
      date = [@range.last, Date.current].min
      @initial_intake_due ||= Health::Patient.intake_due(on: date).pluck(:id)
    end

    def initial_intake_overdue
      date = [@range.last, Date.current].min
      @initial_intake_overdue ||= Health::Patient.intake_overdue(on: date).pluck(:id)
    end

    def intake_renewal_due
      date = [@range.last, Date.current].min
      Health::Patient.where(id: Health::Patient.needs_renewal(on: date).pluck(:id) - Health::Patient.overdue_for_renewal(on: date).pluck(:id)).pluck(:id)
    end

    def intake_renewal_overdue
      date = [@range.last, Date.current].min
      Health::Patient.overdue_for_renewal(on: date).pluck(:id)
    end

    def with_required_wellcare_visit
      anchor = [@range.last, Date.current].min
      @with_required_wellcare_visit ||=
        begin
          set = Set.new
          patient_ids.each_slice(100).each do |patient_id_slice|
            set.merge(
              ClaimsReporting::MedicalClaim.
                annual_well_care_visits.
                service_in(anchor - WELLCARE_WINDOW... anchor).
                joins(:patient).
                where(hp_t[:id].in(patient_id_slice)).
                pluck(hp_t[:id]),
            )
          end

          set.to_a
        end
    end
  end
end
