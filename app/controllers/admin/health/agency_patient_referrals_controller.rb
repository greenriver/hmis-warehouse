###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::Health
  class AgencyPatientReferralsController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_review_patient_assignments!
    before_action :load_agency_users, only: [:review, :reviewed, :add_patient_referral, :claim_buttons]

    include PatientReferral
    helper_method :tab_path_params
    include ArelHelper

    def review
      @active_patient_referral_tab = 'review'
      @display_claim_buttons_for = @user_agencies
      if @user_agencies.any?
        @agency_patient_referral_ids = agency_patient_referral_source.
          where(agency_id: @user_agencies.map(&:id)).
          group_by(&:patient_referral_id).
          delete_if { |_k, v| v.size != @user_agencies.size }.
          keys
        @patient_referrals = patient_referral_source.
          unassigned.
          includes(relationships: :agency, relationships_claimed: :agency).
          references(relationships: :agency, relationships_claimed: :agency).
          where(hapr_t[:id].eq(nil).or(hapr_t[:patient_referral_id].not_in(@agency_patient_referral_ids))).
          preload(:assigned_agency, :aco, :relationships, :relationships_claimed, :relationships_unclaimed, patient: :client)
      end
      respond_to do |format|
        format.html do
          load_index_vars
          render 'index'
        end
        format.xlsx do
          headers['Content-Disposition'] = 'attachment; filename=PatientReferrals.xlsx'
        end
      end
    end

    def reviewed
      @active_patient_referral_tab = 'reviewed'
      @active_patient_referral_group = params[:group] || 'our patient'
      @patient_referral_groups = [
        {
          id: 'our patient',
          path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params.merge(group: 'our patient')),
          title: 'Reviewed as our patient',
        },
        {
          id: 'not our patient',
          path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params.merge(group: 'not our patient')),
          title: 'Reviewed as not our patient',
        },
      ]
      if @user_agencies.any?
        # @patient_referrals = patient_referral_source.
        #   unassigned.
        #   joins(:relationships).
        #   where(agency_patient_referrals: {agency_id: @user_agencies.map(&:id)}).
        #   where(agency_patient_referrals: {claimed: @active_patient_referral_group == 'our patient'}).
        #   preload(:assigned_agency, :aco, :relationships, :relationships_claimed, :relationships_unclaimed, {patient: :client})
        load_index_vars
        @relationships = agency_patient_referral_source.
          joins(:patient_referral).
          where(agency_id: @user_agencies.map(&:id)).
          where(claimed: @active_patient_referral_group == 'our patient').
          where(patient_referrals: { agency_id: nil, rejected: false }).
          includes(patient_referral: { relationships: :agency, relationships_claimed: :agency }).
          references(patient_referral: { relationships: :agency, relationships_claimed: :agency }).
          preload(patient_referral: [:assigned_agency, :aco, :relationships, :relationships_claimed, :relationships_unclaimed, { patient: :client }]).
          group_by do |row|
            @user_agencies.select { |agency| agency.id == row.agency_id }.first
          end

      end
      render 'index'
    end

    # update relationship between patient referral and agency
    def update
      @relationship = agency_patient_referral_source.find(params[:id].to_i)
      build_relationship(@relationship)
    end

    # create relationship between patient referral and agency
    def create
      @new_relationship = agency_patient_referral_source.new(relationship_params)
      build_relationship(@new_relationship)
    end

    def claim_buttons
      @display_claim_buttons_for = @user_agencies
      @patient_referral = patient_referral_source.find(params[:agency_patient_referral_id].to_i)
      render layout: false if request.xhr?
    end

    private

    def build_relationship(relationship)
      @patient_referral = patient_referral_source.find(relationship_params[:patient_referral_id].to_i) if request.xhr?
      # aka agency_patient_referral
      path = relationship.new_record? ? review_admin_health_agency_patient_referrals_path : reviewed_admin_health_agency_patient_referrals_path
      success = relationship.new_record? ? relationship.save : relationship.update(relationship_params)
      if success
        r = relationship.claimed? ? 'Our Patient' : 'Not Our Patient'
        @success = "Patient marked as '#{r}'"
        unless request.xhr?
          flash[:notice] = @success
          redirect_to path
        end
      else
        load_index_vars
        @error = 'An error occurred, please try again.'
        flash[:error] = @error
        render 'index' unless request.xhr?
      end
    end

    def agency_patient_referral_source
      Health::AgencyPatientReferral
    end

    def patient_referral_source
      Health::PatientReferral
    end

    def relationship_params
      params.require(:health_agency_patient_referral).permit(
        :claimed,
        :agency_id,
        :patient_referral_id,
      )
    end

    def load_agency_users
      @agency_users = current_user.agency_users
      @user_agencies = current_user.health_agencies
      @no_agency_user_warning = 'You are not assigned to an agency at this time.  Please request assignment to an agency.' if @user_agencies.none?
    end

    def load_tabs
      @patient_referral_tabs = [
        { id: 'review', tab_text: "Assignments to Review for #{@agency&.name}", path: review_admin_health_agency_patient_referrals_path(tab_path_params) },
        { id: 'reviewed', tab_text: 'Previously Reviewed', path: reviewed_admin_health_agency_patient_referrals_path(tab_path_params) },
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
  end
end
