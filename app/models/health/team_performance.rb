###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def team_counts
      @team_counts ||= teams.map do |name|
        patient_ids = patient_referrals.select do |_, (_, _, team_name)|
          team_name == name
        end.keys

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
            initial_careplan_due_soon: with_initial_careplan_due_in(without_signed_careplans, 28.days),
            initial_careplan_overdue: with_initial_careplan_overdue(without_signed_careplans),
            annual_careplan_due_soon: with_annual_careplan_due_in(patient_ids, 28.days),
            annual_careplan_overdue: with_annual_careplan_overdue(patient_ids),
            without_f2f_in_past_6_months: without_f2f_in_past_6_months,
            with_discharge_followup_completed_within_range: with_discharge_followup,
            with_careplans_in_122_days: with_careplans_in_122_days(patient_ids),
            with_careplans_signed_within_range: with_careplans_signed_within_range(patient_ids),
            with_qualifying_activities_within_range: with_qualifying_activities_within_range,
            without_qualifying_activities_within_range: without_qualifying_activities_within_range,
            with_payable_qualifying_activities_within_range: with_payable_qualifying_activities_within_range,
            without_payable_qualifying_activities_within_range: without_payable_qualifying_activities_within_range,
          },
        )
      end
    end

    def total_counts
      @total_counts ||= OpenStruct.new(
        {
          id: nil,
          name: 'Totals',
          patient_referrals: team_counts.map(&:patient_referrals).reduce(&:+),
          consented_patients: team_counts.map(&:consented_patients).reduce(&:+),
          unconsented_patients: team_counts.map(&:unconsented_patients).reduce(&:+),
          with_ssms: team_counts.map(&:with_ssms).reduce(&:+),
          without_ssms: team_counts.map(&:without_ssms).reduce(&:+),
          with_chas: team_counts.map(&:with_chas).reduce(&:+),
          without_chas: team_counts.map(&:without_chas).reduce(&:+),
          with_signed_careplans: team_counts.map(&:with_signed_careplans).reduce(&:+),
          without_signed_careplans: team_counts.map(&:without_signed_careplans).reduce(&:+),
          initial_careplan_due_soon: team_counts.map(&:initial_careplan_due_soon).reduce(&:+),
          initial_careplan_overdue: team_counts.map(&:initial_careplan_overdue).reduce(&:+),
          annual_careplan_due_soon: team_counts.map(&:annual_careplan_due_soon).reduce(&:+),
          annual_careplan_overdue: team_counts.map(&:annual_careplan_overdue).reduce(&:+),
          without_f2f_in_past_6_months: team_counts.map(&:without_f2f_in_past_6_months).reduce(&:+),
          with_discharge_followup_completed_within_range: team_counts.map(&:with_discharge_followup_completed_within_range).reduce(&:+),
          with_careplans_in_122_days: team_counts.map(&:with_careplans_in_122_days).reduce(&:+),
          with_careplans_signed_within_range: team_counts.map(&:with_careplans_signed_within_range).reduce(&:+),
          with_qualifying_activities_within_range: team_counts.map(&:with_qualifying_activities_within_range).reduce(&:+),
          without_qualifying_activities_within_range: team_counts.map(&:without_qualifying_activities_within_range).reduce(&:+),
          with_payable_qualifying_activities_within_range: team_counts.map(&:with_payable_qualifying_activities_within_range).reduce(&:+),
          without_payable_qualifying_activities_within_range: team_counts.map(&:without_payable_qualifying_activities_within_range).reduce(&:+),
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

    private def most_recent_qa_signature_dates
      # Note: using maximum will ensure the last PCTP, earlier ones don't matter
      @most_recent_qa_signature_dates ||= Health::QualifyingActivity.
        submittable.
        during_current_enrollment.
        where(patient_id: patient_referrals.keys).
        where(activity: :pctp_signed).
        group(:patient_id).maximum(:date_of_activity)
    end

    private def with_initial_careplan_due_in(patient_ids_without_careplans, days_diff)
      due_dates_to_include = (Date.today..Date.today + days_diff)
      patient_ids_without_careplans.select do |p_id|
        enrollment_date = patient_referrals[p_id][0]&.to_date
        enrollment_date.present? && due_dates_to_include.cover?(enrollment_date + 150.days)
      end
    end

    private def with_initial_careplan_overdue(patient_ids_without_careplans)
      patient_ids_without_careplans.select do |p_id|
        enrollment_date = patient_referrals[p_id][0]&.to_date
        enrollment_date.present? && enrollment_date + 150.days < Date.today
      end
    end

    private def with_annual_careplan_due_in(patient_ids, days_diff)
      due_dates_to_include = (Date.today..Date.today + days_diff)
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
