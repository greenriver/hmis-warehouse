module Admin::Health
  class PatientReferralsController < ApplicationController

    def index
      @new_patient_referral = Health::PatientReferral.new()
      @patient_referrals = Health::PatientReferral.all
    end

    def create
      @patient_referral = Health::PatientReferral.new(patient_referral_params)
      if @patient_referral.save
        flash[:notice] = 'New patient referral added.'
      else
        flash[:error] = 'Unable to add patient referral.'
      end
      redirect_to admin_health_patient_referrals_path
    end

    private

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