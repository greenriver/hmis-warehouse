module Admin::Health
  class AgencyPatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_manage_health_agency!
    before_action :load_new_patient_referral, only: [:review, :reviewed]
    before_action :load_agency_user, only: [:review, :reviewed]

    def review
      @active_patient_referral_tab = 'review'
      if @agency.present?
        @agency_patient_referral_ids = Health::AgencyPatientReferral.
          where(agency_id: @agency.id).
          select(:patient_referral_id)
        @patient_referrals = Health::PatientReferral.
          unassigned.includes(:relationships).
          where('agency_patient_referrals.id is null or agency_patient_referrals.patient_referral_id not in (?)', @agency_patient_referral_ids).
          references(:relationships)
      end
      load_index_vars!
      render 'index'
    end

    def reviewed
      @active_patient_referral_tab = 'reviewed'
      if @agency.present?
        @patient_referrals = Health::PatientReferral.
          unassigned.
          joins(:relationships).
          where(agency_patient_referrals: {agency_id: @agency.id})
      end
      load_index_vars!
      render 'index'
    end

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

    def load_show_filters
      @show_filters = false
    end

    def relationship_params
      params.require(:health_agency_patient_referral).permit(
        :claimed,
        :agency_id,
        :patient_referral_id
      )
    end

    def load_agency_user
      @agencies = Health::Agency.all
      @agency_user = Health::AgencyUser.where(user_id: current_user.id).first
      @agency = @agency_user&.agency
      if !@agency
        @no_agency_user_warning = "This user doesn't belong to any agency"
      end
    end

    def load_index_vars!
      load_search!
      @patient_referrals = @patient_referrals.
        page(params[:page].to_i).per(20)
      @patient_referral_tabs = [
        {id: 'review', tab_text: 'Assignments to Review', path: review_admin_health_agency_patient_referrals_path(tab_path_params)},
        {id: 'reviewed', tab_text: 'Previously Reviewed', path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params)}
      ]
    end

    def show_filters?
      false
    end
    helper_method :show_filters?

    def add_patient_referral_path
      add_admin_health_agency_patient_referrals_path
    end
    helper_method :add_patient_referral_path

    def create_patient_referral_success_path
      review_admin_health_agency_patient_referrals_path
    end

  end
end