###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class TeamPerformance
    include ArelHelper

    attr_accessor :range
    def initialize(range:, team_scope: nil)
      @range = (range.first.to_date..range.last.to_date)
      @team_scope = team_scope
    end

    def self.url
      'warehouse_reports/health/agency_performance'
    end

    QA_WINDOW = 60.days
    QA_NO_INTAKE_WINDOW = 30.days
    F2F_WINDOW = 60.days
    COMPLETION_WINDOW = 30.days
    RENEWAL_WINDOW = 365.days
    WELLCARE_WINDOW = 12.months

    DESCRIPTIONS = {
      without_required_qa: 'Patients in their outreach period with no QA in the current month, or who have completed a care plan and have no QA in the current or previous month.',
      without_required_f2f_visit: "Patients who have not received a face-to-face visit in the last #{F2F_WINDOW.inspect}.",
      with_discharge_followup_completed: 'Number of discharge follow-up QAs within the month.',
      with_completed_intake: 'Patients with completed initial intake (Consent, Comp Assessment, HRSN, and Care Plan).',
      initial_intake_due: "Patients who need to receive an initial intake within #{COMPLETION_WINDOW.inspect}.",
      initial_intake_overdue: "Patients who did not complete an initial intake within #{Health::PatientReferral::ENGAGEMENT_IN_DAYS.inspect} of their enrollment.",
      intake_renewal_due: "Patients who need to receive a renewal intake within #{COMPLETION_WINDOW.inspect}.",
      intake_renewal_overdue: "Patients who did not receive a renewal intake within #{RENEWAL_WINDOW.inspect} of their last intake.",
      without_required_wellcare_visit: "Patients that did not have a comprehensive well-care visit with a PCP or an OB/GYN practitioner within the last #{WELLCARE_WINDOW.inspect}. Such visits are identified by paid claims, as specified by the Mathematica Annual Well-Care Visits Measure calculation. *NOTE:* Claims data is approximately 3 months out of date, so any annual well care visits that occured in the past 3 months may not be included.",
    }.freeze

    def team_counts
      @team_counts ||= teams.map do |name|
        patient_ids = patient_referrals.select do |_, (_, _, team_name)|
          team_name == name
        end.keys

        next unless patient_ids.any?

        OpenStruct.new(
          {
            id: nil,
            name: name,
            patient_referrals: patient_ids,
            without_required_qa: patient_ids - with_required_qa,
            without_required_f2f_visit: patient_ids - with_required_f2f_visit,
            with_discharge_followup_completed: with_discharge_followup_completed.select { |id| id.in?(patient_ids) },
            with_completed_intake: with_completed_intake.select { |id| id.in?(patient_ids) },
            initial_intake_due: initial_intake_due.select { |id| id.in?(patient_ids) },
            initial_intake_overdue: initial_intake_overdue.select { |id| id.in?(patient_ids) },
            intake_renewal_due: intake_renewal_due.select { |id| id.in?(patient_ids) },
            intake_renewal_overdue: intake_renewal_overdue.select { |id| id.in?(patient_ids) },
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
          **team_counts.first&.to_h&.keys&.drop(2)&.map { |key| [key, team_counts.map { |o| o[key] }.reduce(&:+)] }.to_h,
        },
      )
    end

    def teams
      @teams ||= team_scope.order(name: :asc).distinct.pluck(:name)
    end

    def team_scope
      @team_scope || Health::CoordinationTeam.all
    end

    def client_ids
      @client_ids ||= Health::Patient.where(id: patient_referrals.keys).
        pluck(:client_id, :id).to_h
    end

    def patient_referrals
      @patient_referrals ||= {}.tap do |hash|
        team_scope.find_each do |team|
          active_patients_in_range = team.patients.
            joins(:patient_referral).
            merge(Health::PatientReferral.active_within_range(start_date: @range.first, end_date: @range.last))

          hash.merge!(
            active_patients_in_range.
              pluck(:patient_id, hpr_t[:enrollment_start_date], lit(team.id.to_s), lit(HealthBase.connection.quote(team.name))).
              group_by(&:shift).
              transform_values(&:flatten),
          )
        end
      end
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
