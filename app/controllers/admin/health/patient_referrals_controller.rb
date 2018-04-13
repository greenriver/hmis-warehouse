module Admin::Health
  class PatientReferralsController < ApplicationController

    before_action :load_index_vars, only: [:index]
    
    def index
      @new_patient_referral = Health::PatientReferral.new()
    end

    def create
      @new_patient_referral = Health::PatientReferral.new(clean_patient_referral_params)
      if @new_patient_referral.save
        flash[:notice] = 'New patient referral added.'
        redirect_to admin_health_patient_referrals_path
      else
        load_index_vars
        flash[:error] = 'Unable to add patient referral.'
        render 'index'
      end
    end

    def assign_agency
      @patient_referral = Health::PatientReferral.find(params[:patient_referral_id])
      if @patient_referral.update_attributes(assign_agency_params)
        flash[:notice] = 'Patient referral assigned to agency.'
      else
        flash[:error] = 'Patient referral could not be assigned.'
      end
      redirect_to admin_health_patient_referrals_path
    end

    private

    def load_index_vars
      @agencies = Health::Agency.all
      @assigned_patient_referrals = Health::PatientReferral.assigned
      @unassigned_patient_referrals = Health::PatientReferral.unassigned
      @patient_referral_tabs = [
        {id: 'referrals-to-review__tab', tab_text: 'Referrals to Review', patient_referrals: @unassigned_patient_referrals},
        {id: 'agency-assigned__tab', tab_text: 'Agency Assigned', patient_referrals: @assigned_patient_referrals}
      ]
      @active_patient_referral_tab = params[:patient_referral_tab] || 'referrals-to-review__tab'
    end

    def assign_agency_params
      params.require(:health_patient_referral).permit(
        :agency_id
      )
    end

    def clean_patient_referral_params
      clean_params = patient_referral_params
      clean_params[:ssn] = clean_params[:ssn].gsub(/\D/, '')
      clean_params
    end

    def patient_referral_params
      params.require(:health_patient_referral).permit(
        :first_name,
        :last_name,
        :birthdate,
        :ssn,
        :medicaid_id
      )
    end

  end
end