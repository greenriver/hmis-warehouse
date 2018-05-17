module Window::Health
  class SdhCaseManagementNotesController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator

    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient

    def show
      @note = Health::SdhCaseManagementNote.find(params[:id])
      render :show
    end

    def new
      @note = @patient.sdh_case_management_notes.build(user: current_user)
      @note.activities.build
    end

    def create
      create_params = note_params.merge({user: current_user})
      @note = @patient.sdh_case_management_notes.build(create_params)
      if @note.save
        redirect_to polymorphic_path(careplan_path_generator)
      else
        render :new
      end
    end

    def edit
      @note = Health::SdhCaseManagementNote.find(params[:id])
      @note.activities.build
    end

    def update
      @note = Health::SdhCaseManagementNote.find(params[:id])
      if @note.update_attributes(note_params)
        redirect_to polymorphic_path(careplan_path_generator)
      else
        render :edit
      end
    end

    def form_url
      if @note.new_record?
        polymorphic_path(sdh_case_management_notes_path_generator, client_id: @client.id)
      else
        polymorphic_path(sdh_case_management_note_path_generator, client_id: @client.id, id: @note.id)
      end
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

    def note_params
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
        activities_attributes: [
          :mode_of_contact, 
          :mode_of_contact_other, 
          :reached_client,
          :reached_client_collateral_contact,
          :activity
        ],
        topics: []
      ).reject{|k, v| v.blank?}.each do |k, v|
        if v.is_a? Array
          v.reject!{|v| v.blank?}
        elsif v.is_a? Hash
          v.reject!{|k, v| v.blank?}
        end
      end
    end
  
  end
end