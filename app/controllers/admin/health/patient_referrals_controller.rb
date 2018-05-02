module Admin::Health
  class PatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_administer_health!
    before_action :load_index_vars, only: [:index]

    Filters = Struct.new(:added_before, :relationship, :agency_id)

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

    def load_filters!
      filter_params = params[:filters] || {}
      @filters = Filters.new(
        filter_params[:added_before], 
        filter_params[:relationship], 
        filter_params[:agency_id]
      )
      if @filters.added_before.present?
        date = DateTime.parse(@filters.added_before)
        added_before_date = DateTime.current.change(year: date.year, month: date.month, day: date.day).beginning_of_day
        @patient_referrals = @patient_referrals.where("created_at < ?", added_before_date)
      end
      if @filters.agency_id.present?
        @patient_referrals = @patient_referrals.
          where('agency_patient_referrals.agency_id = ?', @filters.agency_id).
          references(:relationships)
      end
      if @filters.relationship.present?
        if @filters.relationship != 'all'
          r = @filters.relationship == 'claimed'
          @patient_referrals = @patient_referrals.
            where('agency_patient_referrals.id is not null').
            where('agency_patient_referrals.claimed = ?', r).
            references(:relationships)
        end
      else
        @filters.relationship = 'all'
      end
    end

    def load_search!
      if params[:q].present?
        # @assigned_patient_referrals = @assigned_patient_referrals.text_search(params[:q])
        # @unassigned_patient_referrals = @unassigned_patient_referrals.text_search(params[:q])
        @patient_referrals = @patient_referrals.text_search(params[:q])
      end
    end

    def load_index_vars
      @agencies = Health::Agency.all
      # @assigned_patient_referrals = Health::PatientReferral.assigned
      # @unassigned_patient_referrals = Health::PatientReferral.unassigned
      @patient_referrals = Health::PatientReferral.all.includes(:relationships)
      load_search!
      load_filters!
      @assigned_patient_referrals = @patient_referrals.assigned
      @unassigned_patient_referrals = @patient_referrals.unassigned
      @patient_referral_tabs = [
        {id: 'referrals-to-review__tab', tab_text: 'Assignments to Review', patient_referrals: @unassigned_patient_referrals},
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