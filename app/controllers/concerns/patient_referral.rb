module PatientReferral
  extend ActiveSupport::Concern

  Filters = Struct.new(
    :search, 
    :added_before, 
    :relationship, 
    :agency_id, 
    :sort_by
  )

  def add_patient_referral
    @new_patient_referral = Health::PatientReferral.new(clean_patient_referral_params)
    meets_requirement = can_manage_health_agency? ? claim_agency_eq_user_agency? : true
    if meets_requirement && @new_patient_referral.save
      flash[:notice] = create_patient_referral_notice
      redirect_to create_patient_referral_success_path
    else
      load_index_vars
      flash[:error] = 'Unable to add patient referral.'
      render 'index'
    end
  end

  private

  def load_index_vars
    @agencies = Health::Agency.all
    load_filters
    @patient_referrals = @patient_referrals.
      page(params[:page].to_i).per(20)
    load_tabs
  end

  def load_filters
    filter_params = params[:filters] || {}
    @filters = Filters.new(
      filter_params[:search],
      filter_params[:added_before], 
      filter_params[:relationship], 
      filter_params[:agency_id],
      (filter_params[:sort_by]||'created_at')
    )
    load_search
    filter_added_before
    filter_agency
    filter_relationship
    load_sort
  end

  def load_search
    if @filters.search.present?
      @patient_referrals = @patient_referrals.text_search(@filters.search)
    end
  end

  def load_sort
    order = @filters.sort_by == 'last_name' ? 'last_name' : 'created_at desc'
    @patient_referrals = @patient_referrals.order(order)
  end

  def filter_added_before
    if @filters.added_before.present?
      date = DateTime.parse(@filters.added_before)
      added_before_date = DateTime.current.change(year: date.year, month: date.month, day: date.day).beginning_of_day
      @patient_referrals = @patient_referrals.where("created_at < ?", added_before_date)
    end
  end

  def filter_agency
    if @filters.agency_id.present?
      @filter_agency = Health::Agency.find(@filters.agency_id)
      @patient_referrals = @patient_referrals.
        where('agency_patient_referrals.agency_id = ?', @filters.agency_id).
        references(:relationships)
    end
  end

  def filter_relationship
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

  def tab_path_params
    {filters: params[:filters]}
  end

  def load_new_patient_referral
    @new_patient_referral = Health::PatientReferral.new()  
    if can_manage_health_agency? && @agency.present?
      @new_patient_referral.relationships.build(agency: @agency, claimed: true)
    end
  end

  def clean_patient_referral_params
    clean_params = patient_referral_params
    clean_params[:ssn] = clean_params[:ssn].gsub(/\D/, '')
    clean_params
  end

  def patient_referral_params
    params.require(:health_patient_referral).permit(
      :first_name,
      :last_name,
      :birthdate,
      :ssn,
      :medicaid_id,
      :agency_id,
      relationships_attributes: [:agency_id, :claimed]
    )
  end

end