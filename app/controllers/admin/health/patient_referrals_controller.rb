module Admin::Health
  class PatientReferralsController < ApplicationController

    include PatientReferral

    before_action :require_can_administer_health!
    before_action :load_new_patient_referral, only: [:review, :assigned, :rejected]

    Filters = Struct.new(:added_before, :relationship, :agency_id)

    def review
      @active_patient_referral_tab = 'review'
      @patient_referrals = Health::PatientReferral.unassigned.includes(:relationships)
      load_index_vars!
      render 'index'
    end

    def assigned
      @active_patient_referral_tab = 'assigned'
      @patient_referrals = Health::PatientReferral.assigned.includes(:relationships)
      load_index_vars!
      render 'index'
    end

    def rejected
      # TODO: need more info about what rejected means
      @active_patient_referral_tab = 'rejected'
      @patient_referrals = Health::PatientReferral.all
      load_index_vars!
      render 'index'
    end

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
        @filter_agency = Health::Agency.find(@filters.agency_id)
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

    def load_index_vars!
      @agencies = Health::Agency.all
      load_search!
      load_filters!
      @patient_referrals = @patient_referrals.
        page(params[:page].to_i).per(20)
      @patient_referral_tabs = [
        {id: 'review', tab_text: 'Assignments to Review', path: review_admin_health_patient_referrals_path(tab_path_params)},
        {id: 'assigned', tab_text: 'Agency Assigned', path: assigned_admin_health_patient_referrals_path(tab_path_params)},
        {id: 'rejected', tab_text: 'Refused Consent/Other Rejections', path: rejected_admin_health_patient_referrals_path(tab_path_params)}
      ]
    end

    def assign_agency_params
      params.require(:health_patient_referral).permit(
        :agency_id
      )
    end

    def show_filters?
      true
    end
    helper_method :show_filters?

    def add_patient_referral_path
      admin_health_patient_referrals_path
    end
    helper_method :add_patient_referral_path

    def create_patient_referral_success_path
      review_admin_health_patient_referrals_path
    end

  end
end