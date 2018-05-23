module Window::Health
  class SdhCaseManagementNotesController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator

    before_action :require_can_edit_client_health!
    before_action :require_can_add_case_management_notes!, only: [:new, :create, :edit, :update]
    before_action :set_client
    before_action :set_patient
    before_action :load_template_activity, only: [:edit, :update]

    def show
      @note = Health::SdhCaseManagementNote.find(params[:id])
      render :show
    end

    def new
      @note = @patient.sdh_case_management_notes.
        build(user: current_user, completed_on: DateTime.current)
      @note.save(validate: false)
      redirect_to polymorphic_path([:edit] + sdh_case_management_note_path_generator, client_id: @client.id, id: @note.id)
    end

    def create
      create_params = note_params.merge({user: current_user})
      @note = @patient.sdh_case_management_notes.build(create_params)
      if @note.save
        flash[:notice] = "New SDH Management Note Created."
        redirect_to polymorphic_path(careplans_path_generator)
      else
        flash[:error] = "Please fix the errors below."
        load_template_activity
        render :new
      end
    end

    def edit
      @note = Health::SdhCaseManagementNote.find(params[:id])
      @activities = @note.activities.sort_by(&:id)
      respond_with @note
    end

    def update
      @note = Health::SdhCaseManagementNote.find(params[:id])
      @activity_count = @note.activities.size
      if params[:commit] == 'Save Case Note'
        @note.update_attributes(note_params)
      else
        @note.assign_attributes(note_params)
        @note.save(validate: false)
        @noteAdded = (@activity_count != @note.activities.size)
      end
      @activities = @note.activities.sort_by(&:id)
      respond_with @note, location: polymorphic_path(careplans_path_generator)
    end

    def form_url(opts = {})
      if @note.new_record?
        opts = opts.merge({client_id: @client.id})
        path = sdh_case_management_notes_path_generator
      else
        opts = opts.merge({client_id: @client.id, id: @note.id})
        path = sdh_case_management_note_path_generator
      end
      polymorphic_path(path, opts)
    end
    helper_method :form_url

    def display_note_object
      result = []
      result.push(@note.display_basic_info_section)
      result.push(@note.display_basic_note_section)
      result.push({title: 'Qualifying Activities'})
      if @note.activities.any?
        @note.activities.each_with_index do |activity, index|
          result.push(activity.display_sections(index))
        end
      else
        result.push({values: [{value: 'No Activities'}]})
      end
      result.push(@note.display_additional_questions_section)
      result
    end
    helper_method :display_note_object

    private

    def load_template_activity
      @template_activity = Health::QualifyingActivity.new(user: current_user, user_full_name: current_user.name)
    end

    def clean_note_params!
      # NOTE: Remove COPY from activities_attributes -- if this is present in params we get unpermitted params
      # Let me know if there is a better solution @meborn
      # COPY is used to add activities via js see health/sdh_case_management_note/form_js addActivity
      (params[:health_sdh_case_management_note][:activities_attributes]||{}).reject!{|k,v| k == "COPY"}
      # remove empty element from topics array
      (params[:health_sdh_case_management_note][:topics]||[]).reject!{|v| v.blank?}
    end

    def note_params
      clean_note_params!
      params.require(:health_sdh_case_management_note).permit(
        :title,
        :total_time_spent_in_minutes,
        :date_of_contact,
        :place_of_contact,
        :place_of_contact_other,
        :housing_status,
        :housing_status_other,
        :housing_placement_date,
        :client_action,
        :notes_from_encounter,
        :next_steps,
        :client_phone_number,
        :completed_on,
        topics: [],
        activities_attributes: [
          :id,
          :user_id,
          :user_full_name,
          :mode_of_contact, 
          :mode_of_contact_other, 
          :reached_client,
          :reached_client_collateral_contact,
          :activity,
          :date_of_activity,
          :follow_up
        ]
      ).reject{|k, v| v.blank?}
    end

    def flash_interpolation_options
      { resource_name: 'Case Management Note' }
    end
  
  end
end