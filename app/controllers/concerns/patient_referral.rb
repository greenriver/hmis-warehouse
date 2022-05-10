###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PatientReferral
  extend ActiveSupport::Concern
  include ArelHelper

  Filters = Struct.new(
    :search,
    :added_before,
    :relationship,
    :agency_id,
    :assigned_agency_id,
    :acknowledged_by_mass_health,
    :sort_by,
  )

  private

  def load_index_vars
    @agencies ||= Health::Agency.all
    if @patient_referrals&.exists?
      load_filters
    else
      @patient_referrals = Health::PatientReferral.none
    end
    @pagy, @patient_referrals = pagy(@patient_referrals, items: 3)
    load_tabs
  end

  def load_filters
    filter_params = params[:filters] || {}
    @filters = Filters.new(
      filter_params[:search],
      filter_params[:added_before],
      filter_params[:relationship],
      filter_params[:agency_id],
      filter_params[:assigned_agency_id],
      filter_params[:acknowledged_by_mass_health],
      (filter_params[:sort_by] || 'created_at'),
    )
    load_search
    filter_added_before
    filter_agency
    filter_assigned_agency
    filter_relationship
    filter_acknowledged_by_mass_health
    load_sort
  end

  def load_search
    @patient_referrals = @patient_referrals.text_search(@filters.search) if @filters.search.present?
  end

  def load_sort
    order = @filters.sort_by == 'last_name' ? 'last_name' : hpr_t[:created_at].desc.to_sql
    @patient_referrals = @patient_referrals.order(order)
  end

  def filter_added_before
    return unless @filters.added_before.present?

    @active_filter = true
    date = DateTime.parse(@filters.added_before)
    added_before_date = DateTime.current.change(year: date.year, month: date.month, day: date.day).beginning_of_day
    @patient_referrals = @patient_referrals.where(hpr_t[:created_at].lt(added_before_date))
  end

  def filter_agency
    return unless @filters.agency_id.present?

    @active_filter = true
    @filter_agency = Health::Agency.find(@filters.agency_id)
    @patient_referrals = @patient_referrals.
      where(hapr_t[:agency_id].eq(@filters.agency_id)).
      references(:relationships)
  end

  def filter_assigned_agency
    return unless @filters.assigned_agency_id.present?

    @active_filter = true
    @filter_agency = Health::Agency.find(@filters.assigned_agency_id)
    @patient_referrals = @patient_referrals.
      where(agency_id: @filters.assigned_agency_id).
      references(:relationships)
  end

  def filter_relationship
    if @filters.relationship.present? && @active_patient_referral_tab != 'rejected'
      if @filters.relationship != 'all'
        @active_filter = true
        r = @filters.relationship == 'claimed'
        @patient_referrals = @patient_referrals.
          where(hapr_t[:id].not_eq(nil)).
          where(hapr_t[:claimed].eq(r)).
          references(:relationships)
      end
    else
      @filters.relationship = 'all'
    end
  end

  def filter_acknowledged_by_mass_health
    if @filters.acknowledged_by_mass_health.present? && @active_patient_referral_tab == 'rejected'
      if @filters.acknowledged_by_mass_health != 'all'
        @active_filter = true
        if @filters.acknowledged_by_mass_health == 'true'
          @patient_referrals = @patient_referrals.rejection_confirmed
        else
          @patient_referrals = @patient_referrals.not_confirmed_rejected
        end
      end
    else
      @filters.acknowledged_by_mass_health = 'all'
    end
  end

  def tab_path_params
    params.permit(
      filters:
        [
          :search,
          :added_before,
          :relationship,
          :agency_id,
          :assigned_agency_id,
          :acknowledged_by_mass_health,
          :sort_by,
          :created_at,
        ],
    )
  end

  def clean_patient_referral_params
    clean_params = patient_referral_params
    clean_params[:ssn] = clean_params[:ssn]&.gsub(/\D/, '')
    clean_params
  end

  def patient_referral_params
    params.require(:health_patient_referral).permit(
      :first_name,
      :last_name,
      :birthdate,
      :accountable_care_organization_id,
      :medicaid_id,
      :ssn,
      :effective_date,
      :agency_id,
      :middle_initial,
      :suffix,
      :gender,
      :health_plan_id,
      :cp_assignment_plan,
      :cp_name_dsrip,
      :cp_name_official,
      :cp_pid,
      :cp_sl,
      :enrollment_start_date,
      :start_reason_description,
      :address_line_1,
      :address_line_2,
      :address_city,
      :address_state,
      :address_zip,
      :address_zip_plus_4,
      :email,
      :phone_cell,
      :phone_day,
      :phone_night,
      :primary_language,
      :primary_diagnosis,
      :secondary_diagnosis,
      :pcp_last_name,
      :pcp_last_name,
      :pcp_first_name,
      :pcp_npi,
      :pcp_address_line_1,
      :pcp_address_line_2,
      :pcp_address_city,
      :pcp_address_state,
      :pcp_address_zip,
      :pcp_address_phone,
      :dmh,
      :dds,
      :eoea,
      :ed_visits,
      :snf_discharge,
      :identification,
      :record_status,
      :removal_acknowledged,
      relationships_attributes: [:agency_id, :claimed],
    )
  end
end
