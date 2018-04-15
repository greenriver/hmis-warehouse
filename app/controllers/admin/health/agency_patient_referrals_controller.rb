module Admin::Health
  class AgencyPatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_manage_health_agency!
    before_action :load_index_vars, only: [:index]

    # update relationship between patient referral and agency
    def update
      @relationship = Health::AgencyPatientReferral.find(params[:id])
      if @relationship.update_attributes(relationship_params)
        r = @relationship.claimed? ? 'Our Patient' : 'Not Our Patient'
        flash[:notice] = "Patient referral marked as '#{r}'"
        redirect_to admin_health_agency_patient_referrals_path
      else
        load_index_vars
        flash[:error] = "An error occurred, please try again."
        render 'index'
      end
    end

    # create relationship between patient referral and agency
    def create
      # aka agency_patient_referral
      @new_relationship = Health::AgencyPatientReferral.new(relationship_params)
      if @new_relationship.save
        r = @new_relationship.claimed? ? 'Our Patient' : 'Not Our Patient'
        flash[:notice] = "Patient referral marked as '#{r}'"
        redirect_to admin_health_agency_patient_referrals_path
      else
        load_index_vars
        flash[:error] = "An error occurred, please try again."
        render 'index'
      end
    end

    private

    def relationship_params
      params.require(:health_agency_patient_referral).permit(
        :claimed,
        :agency_id,
        :patient_referral_id
      )
    end

    def load_agency_user
      @agency_user = Health::AgencyUser.where(user_id: current_user.id).first
      @agency = @agency_user.agency if @agency_user.present?
    end

    def load_index_vars
      load_agency_user
      if @agency.present?
        @agencies = Health::Agency.all
        @reviewed_patient_referrals = Health::PatientReferral.
          unassigned.
          joins(:relationships).
          where(agency_patient_referrals: {agency_id: @agency.id})
        @to_review_patient_referrals = Health::PatientReferral.
          unassigned.
          where.not(id: @reviewed_patient_referrals.map(&:id))
        @reviewed_patient_referrals_grouped = @reviewed_patient_referrals.group_by do |pr|
          pr.relationship_to(@agency).claimed?
        end
        @patient_referral_tabs = [
          {id: 'referrals-to-review__tab', tab_text: 'Referrals to Review', patient_referrals: @to_review_patient_referrals},
          {id: 'previously-reviewed__tab', partial_path: 'previously_reviewed', tab_text: 'Previously Reviewed', patient_referrals: @reviewed_patient_referrals_grouped}
        ]
        @active_patient_referral_tab = params[:patient_referral_tab] || 'referrals-to-review__tab'
      else
        @no_agency_user_warning = "This user doesn't belong to any agency"
      end
    end

    def add_patient_referral_path
      add_patient_referral_admin_health_agency_patient_referrals_path
    end
    helper_method :add_patient_referral_path

    def create_patient_referral_success_path
      admin_health_agency_patient_referrals_path
    end

  end
end