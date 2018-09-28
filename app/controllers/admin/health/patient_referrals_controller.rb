module Admin::Health
  class PatientReferralsController < HealthController
    before_action :require_has_administrative_access_to_health!
    before_action :require_can_review_patient_assignments!
    before_action :require_can_approve_patient_assignments!
    before_action :load_new_patient_referral, only: [:review, :assigned, :rejected]

    include PatientReferral

    def review
      @active_patient_referral_tab = 'review'
      @patient_referrals = Health::PatientReferral.unassigned.
        includes(:relationships, relationships_claimed: :agency).
        preload(:assigned_agency, :aco, :relationships, :relationships_unclaimed, {patient: :client})
      respond_to do |format|
        format.html do
          load_index_vars
          render 'index'
        end
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=PatientReferrals.xlsx"
        end
      end
    end

    def assigned
      @active_patient_referral_tab = 'assigned'
      @patient_referrals = Health::PatientReferral.assigned.
        includes(:relationships, relationships_claimed: :agency).
        preload(:assigned_agency, :aco, :relationships, :relationships_claimed, :relationships_unclaimed, {patient: :client})
      load_index_vars
      render 'index'
    end

    def rejected
      @active_patient_referral_tab = 'rejected'
      @patient_referrals = Health::PatientReferral.rejected.
        includes(:relationships, relationships_claimed: :agency).
        preload(:assigned_agency, :aco, :relationships, :relationships_claimed, :relationships_unclaimed, {patient: :client})
      load_index_vars
      @sender = Health::Cp.sender.first
      render 'index'
    end

    def reject
      @patient_referral = Health::PatientReferral.find(params[:patient_referral_id])
      if @patient_referral.update_attributes!(reject_params)
        patient = Health::Patient.with_deleted.
          where(id: @patient_referral.patient_id).first
        if !@patient_referral.rejected_reason_none?
          # Don't destroy the patient, we'll limit patients
          # to patient_referrals.not_confirmed_rejected
          # patient.destroy if patient.present?
          flash[:notice] = "Patient has been rejected."
        else
          patient.restore if patient.present?
          flash[:notice] = "Patient rejection removed."
        end
      else
        @error = 'An error occurred, please try again.'
        flash[:error] = @error
      end
      redirect_to rejected_admin_health_patient_referrals_path unless request.xhr?
    end

    def create
      @new_patient_referral = Health::PatientReferral.new(clean_patient_referral_params)
      if @new_patient_referral.save
        if clean_patient_referral_params[:agency_id].present?
          @new_patient_referral.convert_to_patient()
        end
        flash[:notice] = create_patient_referral_notice
        redirect_to create_patient_referral_success_path
      else
        load_index_vars
        flash[:error] = 'Unable to add patient referral.'
        render 'index'
      end
    end

    def update
      @patient_referral = Health::PatientReferral.find(params[:id].to_i)
      @patient_referral.update(patient_referral_params)
      respond_with(@patient_referral)
    end

    def assign_agency
      @patient_referral = Health::PatientReferral.find(params[:patient_referral_id])
      if @patient_referral.update_attributes(assign_agency_params)
        @patient_referral.convert_to_patient()
        if request.xhr?
          if @patient_referral.assigned_agency.present?
            @success = "Patient assigned to #{@patient_referral.assigned_agency&.name}."
          else
            @success = 'Patient unassigned.'
          end
        else
          if @patient_referral.assigned_agency.present?
            flash[:notice] = "Patient assigned to #{@patient_referral.assigned_agency&.name}."
            redirect_to assigned_admin_health_patient_referrals_path
          else
            flash[:notice] = 'Patient unassigned.'
            redirect_to review_admin_health_patient_referrals_path
          end
        end
      else
        @error = 'Patient could not be assigned.'
        unless request.xhr?
          flash[:error] = @error
          redirect_to review_admin_health_patient_referrals_path
        end
      end
    end

    def bulk_assign_agency
      @params = params[:bulk_assignment] || {}
      @agency = Health::Agency.find(@params[:agency_id]) if @params[:agency_id].present?
      @patient_referrals = Health::PatientReferral.where(id: (@params[:patient_referral_ids] || []))
      if @patient_referrals.any? && @agency.present?
        @patient_referrals.update_all(agency_id: @agency.id)
        @patient_referrals.each do |patient_referral|
          patient_referral.convert_to_patient()
        end
        size = @patient_referrals.size
        flash[:notice] = "#{size} #{'Patient'.pluralize(size)} have been assigned to #{@agency.name}"
        redirect_to assigned_admin_health_patient_referrals_path
      elsif !@agency.present?
        flash[:error] = 'Error: Please select an agency to assign patients to.'
        redirect_to review_admin_health_patient_referrals_path
      elsif !@patient_referrals.any?
        flash[:error] = 'Error: Please select patients to assign.'
        redirect_to review_admin_health_patient_referrals_path
      end

    end

    private

    def load_tabs
      @patient_referral_tabs = [
        {id: 'review', tab_text: 'Assignments to Review', path: review_admin_health_patient_referrals_path(tab_path_params)},
        {id: 'assigned', tab_text: 'Agency Assigned', path: assigned_admin_health_patient_referrals_path(tab_path_params)},
        {id: 'rejected', tab_text: 'Refused Consent/Other Removals', path: rejected_admin_health_patient_referrals_path(tab_path_params)}
      ]
    end

    def reject_params
      params.require(:health_patient_referral).permit(
        :rejected_reason
      )
    end

    def assign_agency_params
      params.require(:health_patient_referral).permit(
        :agency_id
      )
    end

    def filters_path
      case action_name
      when 'review'
        review_admin_health_patient_referrals_path
      when 'assigned'
        assigned_admin_health_patient_referrals_path
      when 'rejected'
        rejected_admin_health_patient_referrals_path
      else
        review_admin_health_patient_referrals_path
      end
    end
    helper_method :filters_path

    def show_filters?
      true
    end
    helper_method :show_filters?

    def add_patient_referral_path
      admin_health_patient_referrals_path
    end
    helper_method :add_patient_referral_path

    def can_bulk_assign?
      action_name == 'review'
    end
    helper_method :can_bulk_assign?

    def create_patient_referral_notice
      if @new_patient_referral.assigned_agency.present?
        "New patient added and assigned to #{@new_patient_referral.assigned_agency&.name}"
      else
        "New patient added."
      end
    end

    def create_patient_referral_success_path
      if @new_patient_referral.assigned_agency.present?
        assigned_admin_health_patient_referrals_path
      else
        review_admin_health_patient_referrals_path
      end
    end
  end
end