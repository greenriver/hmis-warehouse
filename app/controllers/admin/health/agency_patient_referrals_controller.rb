module Admin::Health
  class AgencyPatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_manage_health_agency!
    before_action :load_index_vars, only: [:index]

    private

    def load_index_vars
      @agency_user = Health::AgencyUser.where(user_id: current_user.id).first
      if @agency_user.present?
        @agency = @agency_user.agency
        @agencies = Health::Agency.all
        @reviewed_patient_referrals = Health::PatientReferral.
          unassigned.
          joins(:relationships).
          where(agency_patient_referrals: {agency_id: @agency.id})
        # @reviewed_patient_referrals = Health::AgencyPatientReferral.
        #   where(agency_id: @agency.id).
        #   includes(:patient_referral).
        #   where(patient_referrals: {agency_id: nil}).
        #   group_by(&:patient_referral)
        @to_review_patient_referrals = Health::PatientReferral.
          unassigned.
          where.not(id: @reviewed_patient_referrals.map(&:id))
        @patient_referral_tabs = [
          {id: 'referrals-to-review__tab', tab_text: 'Referrals to Review', patient_referrals: @to_review_patient_referrals},
          {id: 'previously-reviewed__tab', tab_text: 'Previously Reviewed', patient_referrals: @reviewed_patient_referrals}
        ]
        @active_patient_referral_tab = params[:patient_referral_tab] || 'referrals-to-review__tab'
      else
        @no_agency_user_warning = "This user doesn't belong to any agency"
      end
    end

    def create_patient_referral_success_path
      admin_health_agency_patient_referrals_path
    end

  end
end