module Admin::Health
  class AgencyPatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_manage_health_agency!
    before_action :load_agency_user, only: [:review, :reviewed, :add_patient_referral]
    before_action :load_new_patient_referral, only: [:review, :reviewed]

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
        load_index_vars
      end
      render 'index'
    end

    def reviewed
      @active_patient_referral_tab = 'reviewed'
      @active_patient_referral_group = params[:group] || 'our patient'
      @patient_referral_groups = [
        {id: 'our patient', path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params.merge({group: 'our patient'}))},
        {id: 'not our patient', path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params.merge({group: 'not our patient'}))}
      ]
      if @agency.present?
        @patient_referrals = Health::PatientReferral.
          unassigned.
          joins(:relationships).
          where(agency_patient_referrals: {agency_id: @agency.id}).
          where(agency_patient_referrals: {claimed: @active_patient_referral_group == 'our patient'})
        load_index_vars
      end
      render 'index'
    end

    # update relationship between patient referral and agency
    def update
      @relationship = Health::AgencyPatientReferral.find(params[:id])
      build_relationship(@relationship)
    end

    # create relationship between patient referral and agency
    def create
      @new_relationship = Health::AgencyPatientReferral.new(relationship_params)
      build_relationship(@new_relationship)
    end

    private

    def build_relationship(relationship)
      # aka agency_patient_referral
      path = relationship.new_record? ? review_admin_health_agency_patient_referrals_path : reviewed_admin_health_agency_patient_referrals_path 
      success = relationship.new_record? ? relationship.save : relationship.update_attributes(relationship_params)
      if success
        r = relationship.claimed? ? 'Our Patient' : 'Not Our Patient'
        flash[:notice] = "Patient marked as '#{r}'"
        redirect_to path
      else
        load_index_vars
        flash[:error] = "An error occurred, please try again."
        render 'index'
      end
    end

    def relationship_params
      params.require(:health_agency_patient_referral).permit(
        :claimed,
        :agency_id,
        :patient_referral_id
      )
    end

    def load_agency_user
      @agency_user = current_user.agency_user
      @agency = @agency_user&.agency
      if !@agency
        @no_agency_user_warning = "This user doesn't belong to any agency"
      end
    end

    def load_tabs
      @patient_referral_tabs = [
        {id: 'review', tab_text: 'Assignments to Review', path: review_admin_health_agency_patient_referrals_path(tab_path_params)},
        {id: 'reviewed', tab_text: 'Previously Reviewed', path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params)}
      ]
    end

    def filters_path
      case action_name
      when 'review'
        review_admin_health_agency_patient_referrals_path
      when 'reviewed'
        reviewed_admin_health_agency_patient_referrals_path
      else
        review_admin_health_agency_patient_referrals_path
      end
    end
    helper_method :filters_path

    def show_filters?
      false
    end
    helper_method :show_filters?

    def add_patient_referral_path
      add_admin_health_agency_patient_referrals_path
    end
    helper_method :add_patient_referral_path

    def create_patient_referral_notice
      "New patient added and claimed by #{@agency.name}"
    end

    def create_patient_referral_success_path
      reviewed_admin_health_agency_patient_referrals_path(group: 'our patient')
    end

  end
end