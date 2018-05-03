module PatientReferral
  extend ActiveSupport::Concern

  def index
    @new_patient_referral = Health::PatientReferral.new()
  end

  def add_patient_referral
    @new_patient_referral = Health::PatientReferral.new(clean_patient_referral_params)
    if @new_patient_referral.save
      flash[:notice] = 'New patient referral added.'
      redirect_to create_patient_referral_success_path
    else
      load_index_vars
      flash[:error] = 'Unable to add patient referral.'
      render 'index'
    end
  end

  private

  def load_search!
    if params[:q].present?
      @patient_referrals = @patient_referrals.text_search(params[:q])
    end
  end

  def tab_path_params
    {q: params[:q], filters: params[:filters]}
  end

  def load_new_patient_referral
    @new_patient_referral = Health::PatientReferral.new()
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
      :medicaid_id
    )
  end

end