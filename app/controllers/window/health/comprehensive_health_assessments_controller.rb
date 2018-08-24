module Window::Health
  class ComprehensiveHealthAssessmentsController < IndividualPatientController
    helper ChaHelper

    include PjaxModalController
    include WindowClientPathGenerator
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :download, :remove_file, :upload]
    before_action :set_locked, only: [:show, :edit]
    before_action :set_medications, only: [:show, :edit]
    before_action :set_problems, only: [:show, :edit]
    before_action :set_upload_object, only: [:edit, :update, :upload, :remove_file, :download, :remove_file]

    def new
      # redirect to edit if there are any incomplete
      if @patient.comprehensive_health_assessments.incomplete.exists?
        @cha = @patient.comprehensive_health_assessments.incomplete.recent.last
      else
        @cha = @patient.comprehensive_health_assessments.build(user: current_user)
        Health::ChaSaver.new(cha: @cha, user: current_user).create
      end
      redirect_to polymorphic_path([:edit] + cha_path_generator, id: @cha.id)
    end

    def update
      @cha.assign_attributes(form_params)
      Health::ChaSaver.new(cha: @cha, user: current_user, complete: completed?, reviewed: reviewed?).update
      respond_with @cha, location: polymorphic_path(careplans_path_generator) unless request.xhr?
    end

    def edit
      if @cha_locked
        flash.notice = _('A claim was submitted for this CHA; it is no longer editable.')
        redirect_to polymorphic_path(cha_path_generator, id: @cha.id) and return
      end
      # For errors in new/edit forms
      @service = Health::Service.new
      @equipment = Health::Equipment.new
      @services = @patient.services.order(date_requested: :desc)
      @equipments = @patient.equipments
      @blank_cha_url = GrdaWarehouse::PublicFile.url_for_location 'patient/cha'

      respond_with @cha
    end

    def show
      render :show
    end

    def form_url(format_js: false)
      if format_js
        polymorphic_path(cha_path_generator, client_id: @client.id, id: @cha.id)
      else
        polymorphic_path(cha_path_generator, client_id: @client.id, id: @cha.id, format: :js)
      end
    end
    helper_method :form_url

    def upload_url
      polymorphic_path([:upload] + cha_path_generator, client_id: @client.id, id: @cha.id)
    end
    helper_method :upload_url

    private

    def flash_interpolation_options
      { resource_name: 'Comprehensive Health Assessment' }
    end

    def form_params
      local_params = params.require(:form).permit(
        :reviewed_by_supervisor,
        :reviewer,
        :completed,
        *Health::ComprehensiveHealthAssessment::PERMITTED_PARAMS
      )
      local_params
    end

    def set_upload_object
      @upload_object = @cha
      if action_name == 'upload'
        @location = polymorphic_path([:edit] + cha_path_generator, id: @cha.id)
      elsif action_name == 'remove_file'
        @location = polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
      end
      @download_path = @upload_object.downloadable? ? polymorphic_path([:download] + cha_path_generator, client_id: @client.id, id: @cha.id ) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : {confirm: 'Form errors must be fixed before you can download this file.'}
      @remove_path = @upload_object.downloadable? ? polymorphic_path([:remove_file] + cha_path_generator, client_id: @client.id, id: @cha.id ) : '#'
    end

    def set_medications
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)
    end

    def set_problems
      @problems = @patient.problems.order(onset_date: :desc)
    end

    def set_locked
      @cha_locked = @cha.qualifying_activities.submitted.exists?
    end

    def set_form
      @cha = @patient.comprehensive_health_assessments.where(id: params[:id]).first
    end

    def reviewed?
      # update anyone can review a cha now
      # form_params[:reviewed_by_supervisor]=='yes' && current_user.can_approve_cha?
      form_params[:reviewed_by_supervisor]=='yes'
    end

    def completed?
      form_params[:completed] == 'yes' || form_params[:completed] == '1'
    end

  end
end