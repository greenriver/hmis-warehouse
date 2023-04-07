###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class QualifyingActivitiesController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :require_some_patient_access!
    before_action :set_hpc_patient
    before_action :set_qualifying_activities, only: [:index]
    before_action :require_can_unsubmit_submitted_claims!, only: [:destroy]
    before_action :set_qualifying_activity, only: [:destroy, :update, :edit]
    before_action :set_client

    def new
      options = { user: current_user }
      if case_note_in_params?(params)
        options[:source_type] = 'Health::SdhCaseManagementNote'
        options[:source_id] = params[:source_id].to_i
      end
      @qa = @patient.qualifying_activities.new(**options)
    end

    def edit
    end

    def create
      unversioned_params = qa_params.to_h
      @qa = @patient.qualifying_activities.build(date_of_activity: unversioned_params[:date_of_activity], user: current_user, user_full_name: current_user.name)
      unversioned_params.delete_if do |k, _|
        ! k.in?(@qa.qa_version.class.versioned_attribute_names)
      end

      if @qa.update(unversioned_params)
        # Keep the QA tab consistent
        @qa.delay.maintain_cached_values
        # if we have an SDH Case Management Note, we need to set it for the view to work
        @note = Health::SdhCaseManagementNote.find(unversioned_params[:source_id].to_i) if case_note_in_params?(unversioned_params)
        respond_with(@qa) unless request.xhr?
      else # If we throw an error, respond_with knows how to handle it
        respond_with(@qa)
      end
    end

    def update
      unversioned_params = qa_params.to_h
      @qa = @patient.qualifying_activities.build(date_of_activity: unversioned_params[:date_of_activity], user: current_user, user_full_name: current_user.name)
      unversioned_params.delete_if do |k, _|
        ! k.in?(@qa.qa_version.class.versioned_attribute_names)
      end

      if @qa.update(unversioned_params)
        # Keep the QA tab consistent
        @qa.delay.maintain_cached_values
        # if we have an SDH Case Management Note, we need to set it for the view to work
        @note = Health::SdhCaseManagementNote.find(unversioned_params[:source_id].to_i) if case_note_in_params?(unversioned_params)
        if @note.present?
          respond_with(@qa, location: edit_client_health_sdh_case_management_note_path(@client, @note)) unless request.xhr?
        else
          respond_with(@qa)
        end
      else # If we throw an error, respond_with knows how to handle it
        respond_with(@qa)
      end
    end

    def index
      @start_date = params[:start_date]
      @end_date = params[:end_date]
    end

    def destroy
      # Destroy has 2 levels:
      # If the claim was submitted destroy the record of that
      # Otherwise, remove the QA
      if @qa.claim_submitted_on.blank?
        @qa.destroy
        flash[:notice] = 'QA deleted'
      else
        @qa.claim_submitted_on = nil
        @qa.save(validate: false)
        flash[:notice] = 'QA unsubmitted'
      end
      @note = Health::SdhCaseManagementNote.find(params[:source_id].to_i) if case_note_in_params?(params)
      redirect_to(polymorphic_path(health_path_generator + [:qualifying_activities])) unless request.xhr?
    end

    def set_qualifying_activities
      # search / paginate
      @qualifying_activities = @patient.qualifying_activities.
        date_search(params[:start_date], params[:end_date]).
        order(date_of_activity: :desc)
      @pagy, @qualifying_activities = pagy(@qualifying_activities)
    end

    def case_note_in_params?(the_params)
      the_params[:source_type] == 'Health::SdhCaseManagementNote' && the_params[:source_id].present?
    end

    private def qa_params
      versioned_activities_attributes = [
        :id,
        :source_type,
        :source_id,
        :date_of_activity,
        :follow_up,
        :_destroy,
      ].tap do |arr|
        [
          :mode_of_contact,
          :mode_of_contact_other,
          :reached_client,
          :reached_client_collateral_contact,
          :activity,
        ].each do |attr_sym|
          Health::QualifyingActivity::VERSIONS.each do |version|
            name = (attr_sym.to_s + version::ATTRIBUTE_SUFFIX).to_sym
            arr << name
          end
        end
      end
      params.require(:health_qualifying_activity).
        permit(*versioned_activities_attributes)
    end

    protected def title_for_show
      "#{@client.name} - Health - Qualifying Activities"
    end

    protected def set_qualifying_activity
      @qa = @patient.qualifying_activities.find(params[:id].to_i)
    end

    def flash_interpolation_options
      { resource_name: 'Qualifying Activity' }
    end
  end
end
