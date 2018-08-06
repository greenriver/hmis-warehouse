module Window::Health
  class CareplansController < IndividualPatientController
    helper ChaHelper
    include PjaxModalController
    include WindowClientPathGenerator
    include HealthCareplan

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan, only: [:show, :edit, :update, :revise, :destroy, :download, :remove_file, :upload]
    before_action :set_medications, only: [:show]
    before_action :set_problems, only: [:show]
    before_action :set_health_file, only: [:upload, :update]
    before_action :set_epic_goals, only: [:index]

    def index
      @goal = Health::Goal::Base.new
      @readonly = false
      @careplans = @patient.careplans.sorted
      # most-recent careplan
      @careplan = @careplans.first
      @disable_goal_actions = true
      @goals = @careplan&.hpc_goals

      # Callbacks don't work in development, so we have to do something like this
      if Rails.env.development?
        @careplans.each do |cp|
          if cp.primary_signable_document.present?

            doc = cp.primary_signable_document

            # This is trying to ensure we run the same thing here as we do for the callback from HS
            json = {signature_request: doc.fetch_signature_request}.to_json
            response = HelloSignController::CallbackResponse.new(json)
            begin
              response.process!
            rescue ActiveRecord::RecordNotFound
              Rails.logger.fatal "Ignoring a document we couldn't track down."
            end

          end
        end
      end
    end

    def show
      pdf = careplan_combine_pdf_object
      file_name = 'care_plan'
      send_data pdf.to_pdf, filename: "#{file_name}.pdf", type: "application/pdf"
    end

    def edit
      @form_url = polymorphic_path(careplan_path_generator)
      @form_button = 'Save Care Plan'
      @services = @patient.services
      @equipments = @patient.equipments
      # make sure we have the most recent-services and DME if
      # the plan is editable
      if @careplan.editable?
        @careplan.archive_services
        @careplan.archive_equipment
        @careplan.save
      end
    end

    def new
      if @patient.careplans.editable.exists?
        @careplan = @patient.careplans.editable.first
      else
        @careplan = @patient.careplans.new(user: current_user)
        Health::CareplanSaver.new(careplan: @careplan, user: current_user).create
      end

      redirect_to polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
      # @form_url = polymorphic_path(careplans_path_generator)
      # @form_button = 'Create Care Plan'
    end

    def destroy
      @careplan.destroy
      respond_with(@careplan, location: polymorphic_path(careplans_path_generator))
    end

    def print
      @readonly = true
    end

    def revise
      # prevent multiple editable careplans
      if @patient.careplans.editable.exists?
        @careplan = @patient.careplans.editable.first
        redirect_to polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
        return
      end
      new_id = @careplan.revise!
      flash[:notice] = "Careplan revised"
      redirect_to polymorphic_path([:edit] + careplan_path_generator, id: new_id)
    end

    def update
      attributes = careplan_params
      attributes[:user_id] = current_user.id
      @careplan.assign_attributes(attributes)
      Health::CareplanSaver.new(careplan: @careplan, user: current_user).update
      # for errors
      @form_url = polymorphic_path(careplan_path_generator)
      @form_button = 'Save Care Plan'

      respond_with(@careplan, location: polymorphic_path(careplans_path_generator))
    end

    def upload
      if params[:form]
        @careplan.file = @health_file if @health_file
        save_file
      else
        flash[:error] = 'No file was uploaded!  If you are attempting to attach a file, be sure it is in PDF format.'
      end
      respond_with @careplan, location: polymorphic_path([:edit] + careplan_path_generator, id: @careplan.id)
    end

    def download
      @file = @careplan.health_file
      send_data @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      @careplan.health_file.destroy
      respond_with @careplan, location: polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
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
      elsif @careplan.health_file.present?
        @health_file = @careplan.health_file
      end
    end

    def save_file
      if @health_file
        @careplan.health_file = @health_file
        if @careplan.health_file.invalid?
          flash[:error] = @careplan.health_file.errors.full_messages.join(';')
        else
          @careplan.save
        end
      end
    end

    def self_sufficiency_assessment
      @assessment = @client.self_sufficiency_assessments.last
    end

    def set_careplan
      @careplan = careplan_source.find(params[:id].to_i)
    end

    def set_medications
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)
    end

    def set_problems
      @problems = @patient.problems.order(onset_date: :desc)
    end

    def set_epic_goals
      @epic_goals = @patient.epic_goals.visible
    end

    def careplan_source
      Health::Careplan
    end

    def careplan_params
      params.require(:health_careplan).
        permit(
          :initial_date,
          :review_date,
          :patient_signed_on,
          :provider_signed_on,
          :case_manager_id,
          :responsible_team_member_id,
          :responsible_team_member_signed_on,
          :representative_id,
          :representative_signed_on,
          :provider_id,
          :provider_signed_on,
          :patient_health_problems,
          :patient_strengths,
          :patient_goals,
          :patient_barriers,
        )
    end

    def flash_interpolation_options
      { resource_name: 'Care Plan' }
    end

    def new_goal_path
      polymorphic_path([:new] + careplan_path_generator + [:goal], careplan_id: @careplan.id)
    end
    helper_method :new_goal_path

    def edit_goal_path(goal)
      polymorphic_path([:edit] + careplan_path_generator + [:goal], careplan_id: @careplan.id, id: goal.id)
    end
    helper_method :edit_goal_path

    def delete_goal_path(goal)
      polymorphic_path(careplan_path_generator + [:goal], careplan_id: @careplan.id, id: goal.id)
    end
    helper_method :delete_goal_path

  end
end
