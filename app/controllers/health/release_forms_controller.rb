###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ReleaseFormsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file]
    before_action :set_blank_form, only: [:new, :edit, :update, :create]
    before_action :set_upload_object, only: [:edit, :update, :download, :remove_file]

    def new
      # redirect to edit if there are any on-file
      if @patient.release_forms.active.exists?
        @release_form = @patient.release_forms.recent.last
        render(:edit)
        return
      else
        @release_form = @patient.release_forms.build
      end
      render :new
    end

    def create
      @release_form = @patient.release_forms.build(form_params)
      set_upload_object
      @release_form.health_file.set_calculated!(current_user.id, @client.id) if @release_form.health_file.present?
      @release_form.reviewed_by = current_user if reviewed?
      @release_form.user = current_user
      # NOTE: for future people troubleshooting why the submission isn't "remote" when a file is attached
      # https://stackoverflow.com/questions/65135135/rails-6-remote-true-and-multipart-true-file-uploads-not-working
      Health::ReleaseSaver.new(form: @release_form, user: current_user, create_qa: true).create if @release_form.valid?
      respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def show
      render :show
    end

    def edit
      respond_with @release_form
    end

    def update
      @release_form.reviewed_by = current_user if reviewed?
      @release_form.assign_attributes(form_params)
      # NOTE: for future people troubleshooting why the submission isn't "remote" when a file is attached
      # https://stackoverflow.com/questions/65135135/rails-6-remote-true-and-multipart-true-file-uploads-not-working
      @release_form.health_file.set_calculated!(current_user.id, @client.id) if @release_form.health_file&.new_record?
      Health::ReleaseSaver.new(form: @release_form, user: current_user, create_qa: true).update if @release_form.valid?

      respond_with @release_form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    private def set_upload_object
      @upload_object = @release_form
      @location = polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id) if action_name == 'remove_file'
      @download_path = @upload_object.downloadable? ? polymorphic_path([:download] + release_form_path_generator, client_id: @client.id, id: @release_form.id) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : { confirm: 'Form errors must be fixed before you can download this file.' }
      @remove_path = @upload_object.downloadable? ? polymorphic_path([:remove_file] + release_form_path_generator, client_id: @client.id, id: @release_form.id) : '#'
    end

    private def flash_interpolation_options
      { resource_name: 'Release Form' }
    end

    private def form_params
      local_params = params.require(:form).permit(
        :participation_signature_on,
        :signature_on,
        :reviewed_by_supervisor,
        health_file_attributes: [
          :id,
          :file,
          :file_cache,
        ],
      )
      local_params.merge!(mode_of_contact: 'in_person') # Force mode of contact to be in person
      if ! current_user.can_approve_release?
        local_params.except(:reviewed_by_supervisor)
      else
        local_params
      end
    end

    private def set_form
      @release_form = @patient.release_forms.where(id: params[:id]).first
    end

    private def set_blank_form
      @blank_release_form_url = GrdaWarehouse::PublicFile.url_for_location 'patient/release'
      @blank_directed_form_url = GrdaWarehouse::PublicFile.url_for_location 'patient/directed_release'
      @blank_release_form_spanish_url = GrdaWarehouse::PublicFile.url_for_location 'patient/release_spanish'
      @blank_directed_form_spanish_url = GrdaWarehouse::PublicFile.url_for_location 'patient/directed_release_spanish'
    end

    private def health_file_params_blank?
      attrs = form_params[:health_file_attributes] || {}
      attrs[:file].blank? && attrs[:file_cache].blank?
    end

    private def reviewed?
      form_params[:reviewed_by_supervisor] == 'yes' && current_user.can_approve_release?
    end

    private def title_for_show
      "#{@client.name} - Health - Release Form"
    end
  end
end
