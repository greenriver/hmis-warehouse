###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class TeamPerformance
    include ArelHelper

    attr_accessor :range
    def initialize(range:, team_scope: nil, consider_qas: true)
      @range = (range.first.to_date..range.last.to_date)
      @team_scope = team_scope
      @consider_qas = consider_qas
    end

    def self.url
      'warehouse_reports/health/agency_performance'
    end

    DESCRIPTIONS = {
      without_initial_careplan_90_122_days: 'Patients 90-120 days into an enrollment without an initial care plan. To meet the quality metric, initial care plan must be completed within the first 122 days of an enrollment.',
      without_initial_careplan_122_150_days: 'Patients 121-150 days into an enrollment without an initial care plan. For payment, initial care plan must be completed within the first 150 days of an enrollment.',
      initial_careplan_overdue: 'Patients >150 days into an enrollment without an initial care plan.',
      annual_careplan_due_within_30_days: 'Patients with annual care plan due within 30 days. Annual care plans are due 12 months after the patient\'s most recent care plan.',
      annual_careplan_overdue: 'Patients with annual care plan overdue. Annual care plans are due 12 months after the patient\'s most recent care plan.',
      without_annual_well_care_visit_in_12_months: 'Patients that did not have a comprehensive well-care visit with a PCP or an OB/GYN practicioner in the past 12 months. Such visits are identified by paid claims, as specified by the Mathematica Annual Well-Care Visits Measure calculation. *NOTE:* Claims data is approximately 3 months out of date, so any annual well care visits that occured in the past 3 months may not be included.',
      without_f2f_in_past_6_months: 'Patients without QAs for direct face-to-face visits in the past 6 months.',
      with_discharge_followup_completed_within_range: 'Patients with QAs for post-discharge follow ups within the specified date range.',
    }.freeze

    def team_counts
      @team_counts ||= teams.map do |name|
        patient_ids = patient_referrals.select do |_, (_, _, team_name)|
          team_name == name
        end.keys

        next unless patient_ids.any?

        consented_patients = consent_dates.select { |p_id, _| p_id.in?(patient_ids) }.keys
        unconsented_patients = patient_ids - consented_patients

        with_ssms = ssm_dates.keys & patient_ids
        without_ssms = patient_ids - with_ssms

        with_chas = cha_dates.select { |p_id, _| p_id.in?(patient_ids) }.keys
        without_chas = patient_ids - with_chas

        with_signed_careplans = careplan_dates.select { |p_id, _| p_id.in?(patient_ids) }.keys
        without_signed_careplans = patient_ids - with_signed_careplans

        with_qualifying_activities_within_range = qualifying_activity_dates.select { |p_id, _| p_id.in?(patient_ids) }.keys
        without_qualifying_activities_within_range = patient_ids - with_qualifying_activities_within_range

        with_payable_qualifying_activities_within_range = payable_qualifying_activity_dates.select { |p_id, _| p_id.in?(patient_ids) }.keys
        without_payable_qualifying_activities_within_range = patient_ids - with_payable_qualifying_activities_within_range

        without_f2f_in_past_6_months = patient_ids - with_f2f_in_past_6_months
        without_annual_well_care_visit_in_12_months = patient_ids - with_annual_well_care_visit_in_12_months

        with_discharge_followup_within_range = with_discharge_followup.select { |p_id| p_id.in?(patient_ids) }

        OpenStruct.new(
          {
            id: nil,
            name: name,
            patient_referrals: patient_ids,
            consented_patients: consented_patients,
            unconsented_patients: unconsented_patients,
            with_ssms: with_ssms,
            without_ssms: without_ssms,
            with_chas: with_chas,
            without_chas: without_chas,
            with_signed_careplans: with_signed_careplans,
            without_signed_careplans: without_signed_careplans,
            without_initial_careplan_90_122_days: filter_days_since_enrollment(without_signed_careplans, 90...122),
            without_initial_careplan_122_150_days: filter_days_since_enrollment(without_signed_careplans, 122...150),
            initial_careplan_overdue: filter_days_since_enrollment(without_signed_careplans, 150..),
            annual_careplan_due_within_30_days: with_annual_careplan_due_within_30_days(patient_ids),
            annual_careplan_overdue: with_annual_careplan_overdue(patient_ids),
            without_annual_well_care_visit_in_12_months: without_annual_well_care_visit_in_12_months,
            without_f2f_in_past_6_months: without_f2f_in_past_6_months,
            with_discharge_followup_completed_within_range: with_discharge_followup_within_range,
            with_careplans_in_122_days: with_careplans_in_122_days(patient_ids),
            with_careplans_signed_within_range: with_careplans_signed_within_range(patient_ids),
            with_qualifying_activities_within_range: with_qualifying_activities_within_range,
            without_qualifying_activities_within_range: without_qualifying_activities_within_range,
            with_payable_qualifying_activities_within_range: with_payable_qualifying_activities_within_range,
            without_payable_qualifying_activities_within_range: without_payable_qualifying_activities_within_range,
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
          population = team.patients

          if @consider_qas
            patient_ids_with_payable_qas_in_month = population.
              joins(:qualifying_activities).
              merge(Health::QualifyingActivity.payable.in_range(Date.current.beginning_of_month..Date.tomorrow)).
              pluck(:id)

            active_patients_in_range = population.
              joins(:patient_referral).
              merge(Health::PatientReferral.assigned.not_disenrolled).
              or(
                population.
                  joins(:patient_referral).
                  merge(Health::PatientReferral.pending_disenrollment.not_confirmed_rejected).
                  where.not(id: patient_ids_with_payable_qas_in_month),
              )
          else
            active_patients_in_range = population.
              joins(:patient_referral).
              merge(Health::PatientReferral.active_within_range(start_date: @range.first, end_date: @range.last))
          end

          hash.merge!(
            active_patients_in_range.
              pluck(:patient_id, hpr_t[:enrollment_start_date], lit(team.id.to_s), lit(HealthBase.connection.quote(team.name))).
              group_by(&:shift).
              transform_values(&:flatten),
          )
        end
      end
    end

    def consent_dates
      @consent_dates ||= Health::Patient.
        has_signed_participation_form.
        # where(hpf_t[:signature_on].between(@range)).
        pluck(:patient_id, hpf_t[:signature_on].to_sql).to_h
    end

    # accepts an array of hashes, returns a single hash with most-recent values per key
    def patients_with_dates_from_various_sources sources
      patients = {}
      sources.each do |batch|
        batch.each do |p_id, date|
          patients[p_id] = date if patients[p_id].blank? || patients[p_id] < date
        end
      end
      return patients
    end

    # SSMS
    def ssm_dates
      @ssm_dates ||= begin
        hmis_dates = hmis_ssms_max_dates_by_patient_id
        warehouse_dates = warehouse_ssm_dates_by_patient_id
        epic_dates = epic_ssms_by_patient_id

        # determine most recent within range for each patient
        patients_with_dates_from_various_sources([hmis_dates, warehouse_dates, epic_dates])
      end
    end

    def warehouse_ssm_dates_by_patient_id
      @warehouse_ssm_dates_by_patient_id ||= Health::SelfSufficiencyMatrixForm.completed.
        distinct.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        order(completed_at: :asc).
        pluck(:patient_id, :completed_at).to_h
    end

    def hmis_ssms_max_dates_by_patient_id
      @hmis_ssms_max_dates_by_patient_id ||=
        hmis_ssms_max_dates_by_client_id.map do |client_id, date|
          [@client_ids[client_id], date]
        end.to_h
    end

    def hmis_ssms_max_dates_by_client_id
      @hmis_ssms_max_dates_by_client_id ||= GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.self_sufficiency).
        distinct.
        where(id: client_ids.keys). # limit to clients in scope
        pluck(:id, hmis_form_t[:collected_at].to_sql).
        to_h
    end

    def epic_ssms_by_patient_id
      @epic_ssms_by_patient_id ||= Health::EpicSsm.distinct.
        joins(:patient).
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        order(ssm_updated_at: :asc).
        pluck(hp_t[:id].to_sql, :ssm_updated_at).to_h
    end

    # CHAS
    def cha_dates
      @cha_dates ||= begin
        warehouse_dates = warehouse_cha_dates_by_patient_id
        epic_dates = epic_chas_by_patient_id

        # determine most recent within range for each patient
        patients_with_dates_from_various_sources([warehouse_dates, epic_dates])
      end
    end

    def warehouse_cha_dates_by_patient_id
      @warehouse_cha_dates_by_patient_id ||= Health::ComprehensiveHealthAssessment.completed.
        distinct.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        order(completed_at: :asc).
        pluck(:patient_id, :completed_at).to_h
    end

    def epic_chas_by_patient_id
      @epic_chas_by_patient_id ||= Health::EpicCha.distinct.
        joins(:patient).
        where(hp_t[:id].in(patient_referrals.keys)). # limit to patients in scope
        order(cha_updated_at: :asc).
        pluck(hp_t[:id].to_sql, :cha_updated_at).to_h
    end

    # Careplans
    def careplan_dates
      @careplan_dates ||= begin
        warehouse_dates = warehouse_careplan_dates_by_patient_id
        # Ignore Epic care plans for now, 8/31/2018
        # epic_dates = epic_careplan_by_patient_id
        epic_dates = {}
        # determine most recent within range for each patient
        patients_with_dates_from_various_sources([warehouse_dates, epic_dates])
      end
    end

    def warehouse_careplan_dates_by_patient_id
      @warehouse_careplan_dates_by_patient_id ||= Health::Careplan.pcp_signed.
        distinct.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        order(provider_signed_on: :asc).
        pluck(:patient_id, :provider_signed_on).to_h
    end

    def epic_careplan_by_patient_id
      @epic_careplan_by_patient_id ||= Health::EpicCareplan.distinct.
        joins(:patient).
        where(hp_t[:id].in(patient_referrals.keys)). # limit to patients in scope
        order(careplan_updated_at: :asc).
        pluck(hp_t[:id].to_sql, :careplan_updated_at).to_h
    end

    # Qualifying  Activities
    def qualifying_activity_dates
      @qualifying_activity_dates ||= Health::QualifyingActivity.submittable.
        distinct.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        where(date_of_activity: @range).
        order(date_of_activity: :asc).
        pluck(:patient_id, :date_of_activity).to_h
    end

    def payable_qualifying_activity_dates
      @payable_qualifying_activity_dates ||= Health::QualifyingActivity.
        payable.
        not_valid_unpayable.
        distinct.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        where(date_of_activity: @range).
        order(date_of_activity: :asc).
        pluck(:patient_id, :date_of_activity).to_h
    end

    def qa_signature_dates
      # Note: using minimum will ensure the first PCTP, subsequent don't matter
      @qa_signature_dates ||= Health::QualifyingActivity.
        submittable.
        during_current_enrollment.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        where(date_of_activity: @range).
        where(activity: :pctp_signed).
        group(:patient_id).minimum(:date_of_activity)
    end

    private def with_careplans_in_122_days(patient_ids)
      patient_ids.select do |p_id|
        careplan_date = qa_signature_dates[p_id]&.to_date
        enrollment_date = patient_referrals[p_id][0]&.to_date

        careplan_date.present? &&
          enrollment_date.present? &&
          careplan_date.between?(@range.first, @range.last) &&
          (careplan_date - enrollment_date).to_i <= 122
      end
    end

    private def with_careplans_signed_within_range(patient_ids)
      patient_ids.select do |p_id|
        careplan_date = qa_signature_dates[p_id]&.to_date
        careplan_date.present? && careplan_date.between?(@range.first, @range.last)
      end
    end

    private def with_discharge_followup
      @with_discharge_followup ||= Health::QualifyingActivity.
        submittable.
        in_range(@range).
        where(patient_id: patient_referrals.keys).
        where(activity: :discharge_follow_up).
        pluck(:patient_id).uniq
    end

    private def with_f2f_in_past_6_months
      @with_f2f_in_past_6_months ||= Health::QualifyingActivity.
        direct_contact.
        face_to_face.
        where(date_of_activity: (6.months.ago..Date.today)).
        where(patient_id: patient_referrals.keys).
        pluck(:patient_id).uniq
    end

    private def with_annual_well_care_visit_in_12_months
      @with_annual_well_care_visit_in_12_months ||= ClaimsReporting::MedicalClaim.
        annual_well_care_visits.
        service_in(Date.today - 12.months...Date.today).
        joins(:patient).
        where(hp_t[:id].in(patient_referrals.keys)).
        pluck(hp_t[:id]).uniq
    end

    private def most_recent_qa_signature_dates
      # Note: using maximum will ensure the last PCTP, earlier ones don't matter
      @most_recent_qa_signature_dates ||= Health::QualifyingActivity.
        submittable.
        during_current_enrollment.
        where(patient_id: patient_referrals.keys).
        where(activity: :pctp_signed).
        group(:patient_id).maximum(:date_of_activity)
    end

    private def filter_days_since_enrollment(patient_ids, days_since_enrollment_range)
      patient_ids.select do |p_id|
        enrollment_date = patient_referrals[p_id][0]&.to_date
        enrollment_date.present? && days_since_enrollment_range.cover?((Date.today - enrollment_date).to_i)
      end
    end

    private def with_initial_careplan_overdue(patient_ids_without_careplans)
      patient_ids_without_careplans.select do |p_id|
        enrollment_date = patient_referrals[p_id][0]&.to_date
        enrollment_date.present? && enrollment_date + 150.days < Date.today
      end
    end

    private def with_annual_careplan_due_within_30_days(patient_ids)
      due_dates_to_include = (Date.today..Date.today + 30.days)
      patient_ids.select do |p_id|
        latest_careplan_date = most_recent_qa_signature_dates[p_id]&.to_date
        latest_careplan_date.present? && due_dates_to_include.cover?(latest_careplan_date + 12.months)
      end
    end

    private def with_annual_careplan_overdue(patient_ids)
      patient_ids.select do |p_id|
        latest_careplan_date = most_recent_qa_signature_dates[p_id]&.to_date
        latest_careplan_date.present? && latest_careplan_date + 12.months < Date.today
      end
    end
  end
end
