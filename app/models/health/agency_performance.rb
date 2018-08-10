module Health
  class AgencyPerformance
    include ArelHelper

    def initialize range:
      @range = range
    end

    def agencies
      @agencies ||= Health::Agency.pluck(:id, :name).to_h
    end

    def client_ids
      @client_ids ||= Health::Patient.pluck(:client_id, :id).to_h
    end

    def patient_referrals
      @patient_referrals ||= Health::PatientReferral.assigned.
        with_patient.
        pluck(:patient_id, :agency_id)
    end

    def consent_dates
      @consent_dates ||= Health::Patient.
        has_signed_participation_form.
        where(hpf_t[:signature_on].between(@range)).
          pluck(:patient_id, hpf_t[:signature_on].to_sql)
    end

    def ssm_dates
      @ssm_dates ||= begin
        hmis_dates = hmis_ssms_max_dates_by_patient_id
        warehouse_dates = warehouse_ssm_dates_by_patient_id
      end
    end

    def warehouse_ssm_dates_by_patient_id
      @warehouse_ssm_dates_by_patient_id ||= Health::SelfSufficiencyMatrixForm.completed.
        distinct.
        order(h_ssm_t[:completed_at].asc).
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
        order(hmis_form_t[:collected_at].asc).
        where(hmis_form_t[:collected_at].between(@range)).
        pluck(:id, hmis_form_t[:collected_at].to_sql).
        to_h
    end
  end
end