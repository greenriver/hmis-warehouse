###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class SelfSufficiencyMatrixFormsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :destroy, :download, :remove_file, :upload]
    before_action :set_claim_submitted, only: [:show, :edit]
    before_action :set_upload_object, only: [:edit, :update, :upload, :remove_file, :download]

    def new
      # redirect to edit if there are any incomplete
      if @patient.self_sufficiency_matrix_forms.in_progress.exists?
        @form = @patient.self_sufficiency_matrix_forms.in_progress.recent.last
      else
        @form = @patient.self_sufficiency_matrix_forms.build(user: current_user)
      end
      Health::SsmSaver.new(ssm: @form, user: current_user).create
      redirect_to polymorphic_path([:edit] + self_sufficiency_matrix_form_path_generator, id: @form.id)
    end

    def show
      render :show
    end

    def edit
      if @claim_submitted
        flash.notice = 'This qualifying activity has already been submitted and cannot be edited.'
        redirect_to(polymorphic_path(self_sufficiency_matrix_form_path_generator, id: @form.id))
        return
      end
      @blank_ssm_url = GrdaWarehouse::PublicFile.url_for_location 'patient/ssm'
      respond_with @form
    end

    def update
      @form.assign_attributes(form_params)
      Health::SsmSaver.new(ssm: @form, user: current_user).update
      respond_with @form, location: polymorphic_path(careplans_path_generator)
    end

    def destroy
      @form.destroy!
      redirect_to polymorphic_path(careplans_path_generator)
    end

    def form_url
      polymorphic_path(self_sufficiency_matrix_form_path_generator, client_id: @client.id, id: @form.id)
    end
    helper_method :form_url

    def upload_url
      polymorphic_path([:upload] + self_sufficiency_matrix_form_path_generator, client_id: @client.id, id: @form.id)
    end
    helper_method :upload_url

    private def form_params
      params.require(:form).permit(
        :point_completed,
        :housing_score,
        :housing_notes,
        :income_score,
        :income_notes,
        :benefits_score,
        :benefits_notes,
        :disabilities_score,
        :disabilities_notes,
        :food_score,
        :food_notes,
        :employment_score,
        :employment_notes,
        :education_score,
        :education_notes,
        :mobility_score,
        :mobility_notes,
        :life_score,
        :life_notes,
        :healthcare_score,
        :healthcare_notes,
        :physical_health_score,
        :physical_health_notes,
        :mental_health_score,
        :mental_health_notes,
        :substance_abuse_score,
        :substance_abuse_notes,
        :criminal_score,
        :criminal_notes,
        :legal_score,
        :legal_notes,
        :safety_score,
        :safety_notes,
        :risk_score,
        :risk_notes,
        :family_score,
        :family_notes,
        :community_score,
        :community_notes,
        :time_score,
        :time_notes,
        :collection_location,
        :completed_at,
      )
    end

    private def set_upload_object
      @upload_object = @form
      if action_name == 'upload'
        @location = polymorphic_path([:edit] + self_sufficiency_matrix_form_path_generator, id: @form.id)
      elsif action_name == 'remove_file'
        @location = polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      end
      @download_path = @upload_object.downloadable? ? polymorphic_path([:download] + self_sufficiency_matrix_form_path_generator, client_id: @client.id, id: @upload_object.id) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : { confirm: 'Form errors must be fixed before you can download this file.' }
      @remove_path = @upload_object.downloadable? ? polymorphic_path([:remove_file] + self_sufficiency_matrix_form_path_generator, client_id: @client.id, id: @upload_object.id) : '#'
    end

    private def set_form
      @form = @patient.self_sufficiency_matrix_forms.find_by(id: params[:id].to_i)
    end

    private def set_claim_submitted
      @claim_submitted = @form.qualifying_activities.submitted.exists?
    end

    private def flash_interpolation_options
      { resource_name: 'Self-Sufficiency Matrix' }
    end

    private def title_for_show
      "#{@client.name} - Health - SSM"
    end
  end
end
