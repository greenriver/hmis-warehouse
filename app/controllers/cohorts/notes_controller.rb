module Cohorts
  class NotesController < ApplicationController
    include PjaxModalController
    before_action :require_can_view_cohorts!
    before_action :set_note, only: [:destroy]

    def new
      @note = note_source.new(cohort_client_id: params[:cohort_client_id].to_i)
    end

    def create
      @note = note_source.create(note_params.merge({
        cohort_client_id: params[:cohort_client_id],
        user_id: current_user.id,
      }))
      respond_with(@note, location: cohort_path(id: params[:cohort_id].to_i))
    end

    def destroy
      @note.destroy
      respond_with(@note, location: cohort_path(id: params[:cohort_id].to_i))
    end

    def note_params
      params.require(:grda_warehouse_cohort_client_note).permit(
        :note
      )
    end

    def note_source
      GrdaWarehouse::CohortClientNote
    end

    def set_note
      @note = note_source.find(params[:id].to_i)
    end

    def flash_interpolation_options
      { resource_name: "Note for #{@note.client.name}" }
    end
  end
end