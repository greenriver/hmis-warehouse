module Window::Health
  class SdhCaseManagementNotesController < ApplicationController

    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator

    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient

    def new
      @note = @patient.sdh_case_management_notes.build(user: current_user)
      render :new
    end

    def create
      create_params = note_params.merge({user: current_user})
      @note = @patient.sdh_case_management_notes.build(create_params)
      # render :create
      if @note.save
        redirect_to polymorphic_path(careplan_path_generator)
      else
        render :new
      end
    end

    private

    def note_params
      params.require(:health_sdh_case_management_note).permit(
        :title,
        :total_time_spent_in_minutes,
        :date_of_contact,
        :place_of_contact,
        :place_of_contact_other,
        topics: []
      )
    end
  
  end
end