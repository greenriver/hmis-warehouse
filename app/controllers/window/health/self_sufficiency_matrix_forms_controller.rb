module Window::Health
  class SelfSufficiencyMatrixFormsController < IndividualPatientController

    include PjaxModalController
    include WindowClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show, :edit, :update, :destroy, :download, :remove_file, :upload]
    before_action :set_claim_submitted, only: [:show, :edit]
    before_action :set_health_file, only: [:upload, :update]

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
        flash.notice = "This qualifying activity has already been submitted and cannot be edited."
        redirect_to polymorphic_path(self_sufficiency_matrix_form_path_generator, id: @form.id) and return
      end
      @blank_ssm_url = GrdaWarehouse::PublicFile.url_for_location 'patient/ssm'
      respond_with @form
    end

    def update
      @form.assign_attributes(form_params)
      @form.file = @health_file if @health_file
      Health::SsmSaver.new(ssm: @form, user: current_user, complete: params[:commit]=='Save').update
      respond_with @form, location: polymorphic_path(careplans_path_generator)
    end

    def destroy
      @form.destroy!
      redirect_to polymorphic_path(careplans_path_generator)
    end

    def upload
      @form.file = @health_file if @health_file
      save_file if @form.errors.none? && @form.update(form_params)
      respond_with @form, location: polymorphic_path([:edit] + self_sufficiency_matrix_form_path_generator, id: @form.id)
    end

    def download
      @file = @form.health_file
      send_data @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      @form.health_file.destroy
      respond_with @form, location: polymorphic_path(health_path_generator + [:patient, :index], client_id: @client.id)
    end

    def set_health_file
      if file = params.dig(:form, :file)
        @health_file = Health::SsmFile.new(
          user_id: current_user.id,
          client_id: @client.id,
          file: file,
          content: file&.read,
          content_type: file.content_type
        )
      elsif @form.health_file.present?
        @health_file = @form.health_file
      end
    end

    def save_file
      if @health_file
        @form.health_file = @health_file
        @form.save
      end
    end

    private

    def form_params
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
        :collection_location
      )
    end

    def set_form
      @form = @patient.self_sufficiency_matrix_forms.find_by(id: params[:id].to_i)
    end

    def set_claim_submitted
      @claim_submitted = @form.qualifying_activities.submitted.exists?
    end

    def flash_interpolation_options
      { resource_name: 'Self-Sufficiency Matrix' }
    end

  end
end