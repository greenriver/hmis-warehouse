module Admin::Health
  class PatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_administer_health!
    before_action :load_index_vars, only: [:index]

    def create
      add_patient_referral
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

    def add_patient_referral_path
      admin_health_patient_referrals_path
    end
    helper_method :add_patient_referral_path

    def create_patient_referral_success_path
      admin_health_patient_referrals_path
    end

  end
end