###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class AgencyPerformance
    include ArelHelper

    attr_accessor :range
    def initialize range:, agency_scope: nil
      @range = range
      @agency_scope = agency_scope
    end

    def agency_counts
      @agency_counts ||= agencies.map do |id, name|
        patient_ids = patient_referrals.select do |_, (agency_id, _)|
          agency_id == id
        end.keys

        consented_patients = consent_dates.select{ |p_id, _| p_id.in?(patient_ids) }.keys
        unconsented_patients = patient_ids - consented_patients

        with_ssms = ssm_dates.select{ |p_id, _| p_id.in?(patient_ids) }.keys
        without_ssms = patient_ids - with_ssms

        with_chas = cha_dates.select{ |p_id, _| p_id.in?(patient_ids) }.keys
        without_chas = patient_ids - with_chas

        with_signed_careplans = careplan_dates.select{ |p_id, _| p_id.in?(patient_ids) }.keys
        without_signed_careplans = patient_ids - with_signed_careplans

        with_qualifying_activities_within_range = qualifying_activity_dates.select{ |p_id, _| p_id.in?(patient_ids) }.keys
        without_qualifying_activities_within_range = patient_ids - with_qualifying_activities_within_range

        agency = OpenStruct.new(
          {
            id: id,
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
            with_careplans_in_122_days: with_careplans_in_122_days(patient_ids),
            with_careplans_signed_within_range: with_careplans_signed_within_range(patient_ids),
            with_qualifying_activities_within_range: with_qualifying_activities_within_range,
            without_qualifying_activities_within_range: without_qualifying_activities_within_range,
          }
        )
      end
    end

    def total_counts
      @total_counts ||= OpenStruct.new(
        {
          id: nil,
          name: 'Totals',
          patient_referrals: agency_counts.map(&:patient_referrals).reduce(&:+),
          consented_patients: agency_counts.map(&:consented_patients).reduce(&:+),
          unconsented_patients: agency_counts.map(&:unconsented_patients).reduce(&:+),
          with_ssms: agency_counts.map(&:with_ssms).reduce(&:+),
          without_ssms: agency_counts.map(&:without_ssms).reduce(&:+),
          with_chas: agency_counts.map(&:with_chas).reduce(&:+),
          without_chas: agency_counts.map(&:without_chas).reduce(&:+),
          with_signed_careplans: agency_counts.map(&:with_signed_careplans).reduce(&:+),
          without_signed_careplans: agency_counts.map(&:without_signed_careplans).reduce(&:+),
          with_careplans_in_122_days: agency_counts.map(&:with_careplans_in_122_days).reduce(&:+),
          with_careplans_signed_within_range: agency_counts.map(&:with_careplans_signed_within_range).reduce(&:+),
          with_qualifying_activities_within_range: agency_counts.map(&:with_qualifying_activities_within_range).reduce(&:+),
          without_qualifying_activities_within_range: agency_counts.map(&:without_qualifying_activities_within_range).reduce(&:+),
        }
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
      @patient_referrals ||= Health::PatientReferral.assigned.
        not_confirmed_rejected.
        with_patient.
        joins(:patient).
        where(agency_id: agency_scope.select(:id)).
        where(hpr_t[:enrollment_start_date].lt(@range.last)).
        pluck(:patient_id, :agency_id, hpr_t[:enrollment_start_date]).
        reduce({}) do |hash, (patient_id, agency_id, enrollment_start_date)|
          hash.update(patient_id => [agency_id, enrollment_start_date])
        end
    end

    # def rejected_patient_referrals
    #   @rejected_patient_referrals ||= Health::PatientReferral.
    #     rejected.
    #     with_patient.
    #     pluck(:patient_id, :agency_id).to_h
    # end

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
          if patients[p_id].blank? || patients[p_id] < date
            patients[p_id] = date
          end
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
      @hmis_ssms_max_dates_by_patient_id ||= begin
        hmis_ssms_max_dates_by_client_id.map do |client_id, date|
          [@client_ids[client_id], date]
        end.to_h
      end
    end

    def hmis_ssms_max_dates_by_client_id
      @ssms_dates_by_client_id ||= GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).
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
        not_valid_unpayable.
        distinct.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        where(date_of_activity: @range).
        order(date_of_activity: :asc).
        pluck(:patient_id, :date_of_activity).to_h
    end

    def qa_signature_dates
      # Note: using minimum will ensure the first PCTP, subsequent don't matter
      @qa_signatures ||= Health::QualifyingActivity.submittable.
        after_enrollment_date.
        where(patient_id: patient_referrals.keys). # limit to patients in scope
        where(date_of_activity: @range).
        where(activity: :pctp_signed).
        group(:patient_id).minimum(:date_of_activity)
    end

    private def with_careplans_in_122_days(patient_ids)
      patient_ids.select do |p_id|
        careplan_date = qa_signature_dates[p_id]&.to_date
        enrollment_date = patient_referrals[p_id][1]
        careplan_date.present? && careplan_date.between?(@range.first, @range.last) && (careplan_date - enrollment_date).to_i <= 122
      end
    end

    private def with_careplans_signed_within_range(patient_ids)
      patient_ids.select do |p_id|
        careplan_date = qa_signature_dates[p_id]&.to_date
        careplan_date.present? && careplan_date.between?(@range.first, @range.last)
      end
    end

  end
end