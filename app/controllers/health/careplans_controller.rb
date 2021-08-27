###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class CareplansController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthCareplan
    include HealthFileController

    helper ChaHelper

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan, only: [:show, :edit, :update, :revise, :destroy, :download, :remove_file, :upload, :pctp]
    before_action :set_medications, only: [:show]
    before_action :set_problems, only: [:show]
    before_action :set_upload_object, only: [:edit, :update, :revise, :remove_file, :download, :upload]
    before_action :set_epic_goals, only: [:index]

    def index
      @goal = Health::Goal::Base.new
      @readonly = false
      @patient = @patient ||= Health::Patient.new
      @careplans = @patient&.careplans&.sorted
      # most-recent careplan
      @careplan = @careplans&.first
      @disable_goal_actions = true
      @goals = @careplan&.hpc_goals

      # Callbacks don't work in development, so we have to do something like this
      return unless Rails.env.development?

      @careplans&.each do |cp|
        [cp.pcp_signable_documents.un_fetched_document, cp.patient_signable_documents.un_fetched_document].flatten.each do |doc|
          begin
            # This is trying to ensure we run the same thing here as we do for the callback from HS
            json = { signature_request: doc.fetch_signature_request }.to_json
            response = HelloSignController::CallbackResponse.new(json)
          rescue HelloSign::Error::NotFound
            Rails.logger.fatal "Ignoring a document we couldn't track down."
          end
          begin
            response.process!
          rescue ActiveRecord::RecordNotFound
            Rails.logger.fatal "Ignoring a document we couldn't track down."
          rescue Exception
            Rails.logger.fatal "Ignoring a document we couldn't track down."
          end
        end
      end
    end

    def show
      pdf = careplan_combine_pdf_object
      file_name = 'care_plan'
      send_data pdf.to_pdf, filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    def edit
      @modal_size = :xl
      @form_url = polymorphic_path(careplan_path_generator)
      @form_button = 'Save Care Plan'
      @services = @patient.services
      @equipments = @patient.equipments
      @disable_goal_actions = @careplan.locked?
      # make sure we have the most recent-services and DME if
      # the plan is editable
      return unless @careplan.editable?

      @careplan.archive_services
      @careplan.archive_equipment
      @careplan.archive_backup_plans
      @careplan.save
    end

    def new
      if @patient.careplans.editable.exists?
        @careplan = @patient.careplans.editable.first
      else
        @careplan = @patient.careplans.new(user: current_user)
        Health::CareplanSaver.new(careplan: @careplan, user: current_user, create_qa: false).create
      end

      redirect_to polymorphic_path([:edit] + careplan_path_generator, id: @careplan)
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
      flash[:notice] = 'Careplan revised'
      redirect_to polymorphic_path([:edit] + careplan_path_generator, id: new_id)
    end

    def update
      @careplan.user = current_user
      @careplan.assign_attributes(careplan_params)
      @careplan.health_file.set_calculated!(current_user.id, @client.id) if @careplan.health_file&.new_record?
      Health::CareplanSaver.new(careplan: @careplan, user: current_user, create_qa: true).update
      @form_button = 'Save Care Plan'
      respond_with(@careplan, location: polymorphic_path(careplans_path_generator))
    end

    def coversheet
      pdf = careplan_pdf_coversheet
      file_name = 'care_plan_coversheet'
      send_data pdf.to_pdf, filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    def pctp
      @document = 'pctp'
      pdf = careplan_pdf_coversheet
      pdf << careplan_pdf_pctp
      file_name = 'care_plan_pctp'
      send_data pdf.to_pdf, filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    def form_url
      polymorphic_path(careplan_path_generator)
    end
    helper_method :form_url

    def set_upload_object
      @upload_object = @careplan
      @location = polymorphic_path([:edit] + careplan_path_generator, id: @careplan.id)
      @download_path = @upload_object.downloadable? ? polymorphic_path([:download] + careplan_path_generator, client_id: @client.id, id: @careplan.id) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : { confirm: 'Form errors must be fixed before you can download this file.' }
      @remove_path = @upload_object.downloadable? ? polymorphic_path([:remove_file] + careplan_path_generator, client_id: @client.id, id: @careplan.id) : '#'
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
      @epic_goals = @patient&.epic_goals&.visible
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
          :patient_signature_mode,
          :provider_signed_on,
          :provider_signature_mode,
          :case_manager_id,
          :responsible_team_member_id,
          :responsible_team_member_signed_on,
          :representative_id,
          :representative_signed_on,
          :provider_id,
          :provider_signature_requested_at,
          :patient_health_problems,
          :patient_strengths,
          :patient_goals,
          :patient_barriers,
          :future_issues_0,
          :future_issues_1,
          :future_issues_2,
          :future_issues_3,
          :future_issues_4,
          :future_issues_5,
          :future_issues_6,
          :future_issues_7,
          :future_issues_8,
          :future_issues_9,
          :future_issues_10,
          :member_understands_contingency,
          :member_verbalizes_understanding,
          health_file_attributes: [
            :id,
            :file,
            :file_cache,
          ],
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

    protected def title_for_show
      "#{@client.name} - Health - Careplans"
    end
  end
end
