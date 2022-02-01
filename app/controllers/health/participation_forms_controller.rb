###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ParticipationFormsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]
    before_action :set_blank_form, only: [:edit, :new, :remove_file]
    before_action :set_upload_object, only: [:edit, :update, :download, :remove_file]

    def new
      # redirect to edit if there are any on-file
      if @patient.participation_forms.active.exists?
        @participation_form = @patient.participation_forms.recent.last
        render(:edit)
        return
      else
        @participation_form = @patient.participation_forms.build
      end
      render :new
    end

    def create
      @participation_form = @patient.participation_forms.build(form_params)
      set_upload_object
      @participation_form.health_file.set_calculated!(current_user.id, @client.id) if @participation_form.health_file.present?
      @participation_form.reviewed_by = current_user if reviewed?
      @participation_form.case_manager = current_user

      if ! request.xhr?
        Health::ParticipationSaver.new(form: @participation_form, user: current_user).create
        respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      elsif @participation_form.valid?
        Health::ParticipationSaver.new(form: @participation_form, user: current_user).create
      end
    end

    def show
      render :show
    end

    def edit
      respond_with @participation_form
    end

    def update
      @participation_form.reviewed_by = current_user if reviewed?
      @participation_form.assign_attributes(form_params)

      @participation_form.health_file.set_calculated!(current_user.id, @client.id) if @participation_form.health_file&.new_record?
      if ! request.xhr?
        Health::ParticipationSaver.new(form: @participation_form, user: current_user).update
        respond_with @participation_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      elsif @participation_form.valid?
        Health::ParticipationSaver.new(form: @participation_form, user: current_user).update
      end
    end

    private def set_upload_object
      @upload_object = @participation_form
      @location = polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id) if action_name == 'remove_file'
      @download_path = @upload_object.downloadable? ? polymorphic_path([:download] + participation_form_path_generator, client_id: @client.id, id: @participation_form.id) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : { confirm: 'Form errors must be fixed before you can download this file.' }
      @remove_path = @upload_object.downloadable? ? polymorphic_path([:remove_file] + participation_form_path_generator, client_id: @client.id, id: @participation_form.id) : '#'
    end

    private def flash_interpolation_options
      { resource_name: 'Participation Form' }
    end

    private def form_params
      local_params = params.require(:form).permit(
        :signature_on,
        :reviewed_by_supervisor,
        :verbal_approval,
        health_file_attributes: [
          :id,
          :file,
          :file_cache,
        ],
      )
      if ! current_user.can_approve_participation?
        local_params.except(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    private def set_form
      @participation_form = @patient.participation_forms.where(id: params[:id]).first
    end

    private def set_blank_form
      @blank_participation_form_url = GrdaWarehouse::PublicFile.url_for_location 'patient/participation'
    end

    private def form_url(_opts = {})
      if @participation_form.new_record?
        polymorphic_path(participation_forms_path_generator, client_id: @client.id)
      else
        polymorphic_path(participation_form_path_generator, client_id: @client.id, id: @participation_form.id)
      end
    end
    helper_method :form_url

    private def health_file_params_blank?
      attrs = form_params[:health_file_attributes] || {}
      attrs[:file].blank? && attrs[:file_cache].blank?
    end

    private def reviewed?
      form_params[:reviewed_by_supervisor] == 'yes' && current_user.can_approve_participation?
    end

    private def title_for_show
      "#{@client.name} - Health - Participation Form"
    end
  end
end
